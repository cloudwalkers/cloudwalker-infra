package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestEC2Module(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	// Get the default VPC and subnets for testing
	vpc := aws.GetDefaultVpc(t, awsRegion)
	subnets := aws.GetSubnetsForVpc(t, vpc.Id, awsRegion)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/ec2-basic",

		Vars: map[string]interface{}{
			"name_prefix":       namePrefix,
			"ami_id":           aws.GetAmazonLinuxAmi(t, awsRegion),
			"instance_type":    "t2.micro",
			"key_name":         "test-key", // You'll need to create this key pair
			"subnet_ids":       []string{subnets[0].Id, subnets[1].Id},
			"desired_capacity": 2,
			"min_size":         1,
			"max_size":         3,
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	launchTemplateId := terraform.Output(t, terraformOptions, "launch_template_id")
	asgName := terraform.Output(t, terraformOptions, "autoscaling_group_name")

	// Verify Launch Template exists
	launchTemplate := aws.GetLaunchTemplate(t, awsRegion, launchTemplateId)
	assert.NotNil(t, launchTemplate)
	assert.Contains(t, launchTemplate.LaunchTemplateName, namePrefix)

	// Verify Auto Scaling Group exists and has correct configuration
	asg := aws.GetAutoScalingGroup(t, awsRegion, asgName)
	assert.NotNil(t, asg)
	assert.Equal(t, int64(2), asg.DesiredCapacity)
	assert.Equal(t, int64(1), asg.MinSize)
	assert.Equal(t, int64(3), asg.MaxSize)

	// Wait for instances to be running
	aws.WaitForCapacity(t, asg, 2, 5*time.Minute, awsRegion)

	// Verify instances are running
	instances := aws.GetInstancesInAsg(t, asg, awsRegion)
	assert.Equal(t, 2, len(instances))

	for _, instance := range instances {
		assert.Equal(t, "running", instance.State.Name)
	}
}

func TestEC2ModuleWithScalingPolicies(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	vpc := aws.GetDefaultVpc(t, awsRegion)
	subnets := aws.GetSubnetsForVpc(t, vpc.Id, awsRegion)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/ec2-with-scaling",

		Vars: map[string]interface{}{
			"name_prefix":             namePrefix,
			"ami_id":                 aws.GetAmazonLinuxAmi(t, awsRegion),
			"instance_type":          "t2.micro",
			"key_name":               "test-key",
			"subnet_ids":             []string{subnets[0].Id, subnets[1].Id},
			"desired_capacity":       1,
			"min_size":               1,
			"max_size":               5,
			"enable_scaling_policies": true,
			"cpu_high_threshold":     80,
			"cpu_low_threshold":      20,
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify scaling policies were created
	scaleUpPolicyArn := terraform.Output(t, terraformOptions, "scale_up_policy_arn")
	scaleDownPolicyArn := terraform.Output(t, terraformOptions, "scale_down_policy_arn")

	assert.NotEmpty(t, scaleUpPolicyArn)
	assert.NotEmpty(t, scaleDownPolicyArn)

	// Verify CloudWatch alarms were created
	cpuHighAlarmArn := terraform.Output(t, terraformOptions, "cpu_high_alarm_arn")
	cpuLowAlarmArn := terraform.Output(t, terraformOptions, "cpu_low_alarm_arn")

	assert.NotEmpty(t, cpuHighAlarmArn)
	assert.NotEmpty(t, cpuLowAlarmArn)
}