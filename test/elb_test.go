package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestELBModule(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	// Get default VPC and subnets
	vpc := aws.GetDefaultVpc(t, awsRegion)
	subnets := aws.GetSubnetsForVpc(t, vpc.Id, awsRegion)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/elb-basic",

		Vars: map[string]interface{}{
			"name":                namePrefix,
			"vpc_id":              vpc.Id,
			"subnet_ids":          []string{subnets[0].Id, subnets[1].Id},
			"load_balancer_type":  "application",
			"internal":            false,
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Get outputs
	albArn := terraform.Output(t, terraformOptions, "load_balancer_arn")
	albDnsName := terraform.Output(t, terraformOptions, "load_balancer_dns_name")
	securityGroupId := terraform.Output(t, terraformOptions, "security_group_id")

	// Verify ALB exists
	alb := aws.GetLoadBalancerV2(t, awsRegion, albArn)
	assert.NotNil(t, alb)
	assert.Equal(t, "application", alb.Type)
	assert.Equal(t, "internet-facing", alb.Scheme)
	assert.NotEmpty(t, albDnsName)

	// Verify security group exists
	sg := aws.GetSecurityGroupById(t, securityGroupId, awsRegion)
	assert.NotNil(t, sg)
	assert.Equal(t, vpc.Id, sg.VpcId)
}

func TestELBModuleWithTargetGroups(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	vpc := aws.GetDefaultVpc(t, awsRegion)
	subnets := aws.GetSubnetsForVpc(t, vpc.Id, awsRegion)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/elb-with-target-groups",

		Vars: map[string]interface{}{
			"name":               namePrefix,
			"vpc_id":             vpc.Id,
			"subnet_ids":         []string{subnets[0].Id, subnets[1].Id},
			"load_balancer_type": "application",
			"target_groups": map[string]interface{}{
				"web-servers": map[string]interface{}{
					"port":     80,
					"protocol": "HTTP",
					"health_check": map[string]interface{}{
						"path":    "/health",
						"matcher": "200",
					},
				},
			},
			"listener_rules": map[string]interface{}{
				"http": map[string]interface{}{
					"port":     80,
					"protocol": "HTTP",
					"default_action": map[string]interface{}{
						"type":               "forward",
						"target_group_name":  "web-servers",
					},
				},
			},
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify target groups were created
	targetGroupArns := terraform.OutputMap(t, terraformOptions, "target_group_arns")
	assert.Contains(t, targetGroupArns, "web-servers")
	assert.NotEmpty(t, targetGroupArns["web-servers"])

	// Verify listeners were created
	listenerArns := terraform.OutputMap(t, terraformOptions, "listener_arns")
	assert.Contains(t, listenerArns, "http")
	assert.NotEmpty(t, listenerArns["http"])
}