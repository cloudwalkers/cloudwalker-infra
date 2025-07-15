package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestCompleteInfrastructureStack tests a complete infrastructure stack
func TestCompleteInfrastructureStack(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	// VPC Configuration
	vpcOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/vpc-basic",
		Vars: map[string]interface{}{
			"name_prefix":             namePrefix,
			"vpc_cidr_block":          "10.0.0.0/16",
			"public_subnet_cidrs":     []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs":    []string{"10.0.10.0/24", "10.0.20.0/24"},
			"allowed_ips":             []string{"0.0.0.0/0"},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// Clean up VPC resources
	defer terraform.Destroy(t, vpcOptions)

	// Deploy VPC
	terraform.InitAndApply(t, vpcOptions)

	// Get VPC outputs
	vpcId := terraform.Output(t, vpcOptions, "vpc_id")
	publicSubnetIds := terraform.OutputList(t, vpcOptions, "public_subnet_ids")
	privateSubnetIds := terraform.OutputList(t, vpcOptions, "private_subnet_ids")

	// Verify VPC was created correctly
	vpc := aws.GetVpcById(t, vpcId, awsRegion)
	assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)

	// ELB Configuration
	elbOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/elb-with-vpc",
		Vars: map[string]interface{}{
			"name":       namePrefix + "-alb",
			"vpc_id":     vpcId,
			"subnet_ids": publicSubnetIds,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// Clean up ELB resources
	defer terraform.Destroy(t, elbOptions)

	// Deploy ELB
	terraform.InitAndApply(t, elbOptions)

	// Get ELB outputs
	albArn := terraform.Output(t, elbOptions, "load_balancer_arn")
	targetGroupArns := terraform.OutputMap(t, elbOptions, "target_group_arns")

	// Verify ALB was created
	alb := aws.GetLoadBalancerV2(t, awsRegion, albArn)
	assert.NotNil(t, alb)
	assert.Equal(t, "application", alb.Type)

	// EC2 Configuration
	ec2Options := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/ec2-with-alb",
		Vars: map[string]interface{}{
			"name_prefix":        namePrefix + "-ec2",
			"ami_id":            aws.GetAmazonLinuxAmi(t, awsRegion),
			"instance_type":     "t2.micro",
			"key_name":          "test-key",
			"subnet_ids":        privateSubnetIds,
			"target_group_arns": []string{targetGroupArns["web-servers"]},
			"desired_capacity":  2,
			"min_size":          1,
			"max_size":          3,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// Clean up EC2 resources
	defer terraform.Destroy(t, ec2Options)

	// Deploy EC2
	terraform.InitAndApply(t, ec2Options)

	// Get EC2 outputs
	asgName := terraform.Output(t, ec2Options, "autoscaling_group_name")

	// Verify Auto Scaling Group
	asg := aws.GetAutoScalingGroup(t, awsRegion, asgName)
	assert.NotNil(t, asg)
	assert.Equal(t, int64(2), asg.DesiredCapacity)

	// Wait for instances to be healthy
	aws.WaitForCapacity(t, asg, 2, 10*time.Minute, awsRegion)

	// Verify instances are running and healthy
	instances := aws.GetInstancesInAsg(t, asg, awsRegion)
	assert.Equal(t, 2, len(instances))

	for _, instance := range instances {
		assert.Equal(t, "running", instance.State.Name)
	}

	// Test load balancer health
	// Note: In a real test, you might want to deploy a simple web server
	// and test that the load balancer can reach it
}

// TestModuleUpgrade tests upgrading a module to a new version
func TestModuleUpgrade(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/vpc-basic",
		Vars: map[string]interface{}{
			"name_prefix":             namePrefix,
			"vpc_cidr_block":          "10.0.0.0/16",
			"public_subnet_cidrs":     []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs":    []string{"10.0.10.0/24", "10.0.20.0/24"},
			"allowed_ips":             []string{"0.0.0.0/0"},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	// Initial deployment
	terraform.InitAndApply(t, terraformOptions)

	// Get initial state
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	initialSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")

	// Simulate an upgrade by changing configuration
	terraformOptions.Vars["allowed_ips"] = []string{"10.0.0.0/8"}

	// Apply upgrade
	terraform.Apply(t, terraformOptions)

	// Verify VPC ID hasn't changed (no replacement)
	newVpcId := terraform.Output(t, terraformOptions, "vpc_id")
	assert.Equal(t, vpcId, newVpcId)

	// Verify subnets are still the same
	newSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	assert.ElementsMatch(t, initialSubnetIds, newSubnetIds)
}

// TestDisasterRecovery tests disaster recovery scenarios
func TestDisasterRecovery(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/vpc-basic",
		Vars: map[string]interface{}{
			"name_prefix":             namePrefix,
			"vpc_cidr_block":          "10.0.0.0/16",
			"public_subnet_cidrs":     []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs":    []string{"10.0.10.0/24", "10.0.20.0/24"},
			"allowed_ips":             []string{"0.0.0.0/0"},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	// Initial deployment
	terraform.InitAndApply(t, terraformOptions)

	// Get initial outputs
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	subnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")

	// Simulate disaster by manually deleting a subnet
	aws.DeleteSubnet(t, subnetIds[0], awsRegion)

	// Run terraform plan to see what needs to be recreated
	planOutput := terraform.Plan(t, terraformOptions)
	assert.Contains(t, planOutput, "will be created")

	// Apply to recover from disaster
	terraform.Apply(t, terraformOptions)

	// Verify recovery
	newVpcId := terraform.Output(t, terraformOptions, "vpc_id")
	newSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")

	assert.Equal(t, vpcId, newVpcId)
	assert.Equal(t, 2, len(newSubnetIds))
}