package test

import (
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestCompleteStackIntegration(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete-stack",

		Vars: map[string]interface{}{
			"name_prefix":   namePrefix,
			"environment":   "test",
			"project_name":  "integration-test",
			"owner":         "terratest",
			"ami_id":        aws.GetAmazonLinuxAmi(t, awsRegion),
			"key_name":      "test-key", // You'll need to create this key pair
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Test VPC Integration
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")

	assert.NotEmpty(t, vpcId)
	assert.Equal(t, 2, len(publicSubnetIds))
	assert.Equal(t, 2, len(privateSubnetIds))

	// Verify VPC exists
	vpc := aws.GetVpcById(t, vpcId, awsRegion)
	assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)

	// Test IAM Integration
	iamRoleArns := terraform.OutputMap(t, terraformOptions, "iam_role_arns")
	iamPolicyArns := terraform.OutputMap(t, terraformOptions, "iam_policy_arns")
	ec2InstanceProfileName := terraform.Output(t, terraformOptions, "ec2_instance_profile_name")

	// Verify IAM roles were created
	expectedRoles := []string{"ec2-instance-role", "ecs-execution-role", "ecs-task-role", "eks-cluster-role", "eks-node-group-role"}
	for _, roleName := range expectedRoles {
		assert.Contains(t, iamRoleArns, roleName)
		assert.NotEmpty(t, iamRoleArns[roleName])
	}

	// Verify custom policy was created
	assert.Contains(t, iamPolicyArns, "s3-app-access")
	assert.NotEmpty(t, iamPolicyArns["s3-app-access"])

	// Verify instance profile exists
	assert.NotEmpty(t, ec2InstanceProfileName)
	instanceProfile := aws.GetIamInstanceProfile(t, ec2InstanceProfileName)
	assert.Equal(t, ec2InstanceProfileName, instanceProfile.InstanceProfileName)

	// Test Storage Integration
	s3BucketName := terraform.Output(t, terraformOptions, "s3_bucket_name")
	s3BucketArn := terraform.Output(t, terraformOptions, "s3_bucket_arn")
	efsId := terraform.Output(t, terraformOptions, "efs_id")
	efsDnsName := terraform.Output(t, terraformOptions, "efs_dns_name")

	assert.NotEmpty(t, s3BucketName)
	assert.NotEmpty(t, s3BucketArn)
	assert.NotEmpty(t, efsId)
	assert.NotEmpty(t, efsDnsName)

	// Verify S3 bucket exists
	aws.AssertS3BucketExists(t, awsRegion, s3BucketName)

	// Test Load Balancer Integration
	albDnsName := terraform.Output(t, terraformOptions, "alb_dns_name")
	albZoneId := terraform.Output(t, terraformOptions, "alb_zone_id")
	targetGroupArns := terraform.OutputMap(t, terraformOptions, "target_group_arns")

	assert.NotEmpty(t, albDnsName)
	assert.NotEmpty(t, albZoneId)
	assert.Contains(t, targetGroupArns, "web-servers")
	assert.Contains(t, targetGroupArns, "api-servers")

	// Test EC2 Integration
	ec2AsgName := terraform.Output(t, terraformOptions, "ec2_autoscaling_group_name")
	ec2LaunchTemplateId := terraform.Output(t, terraformOptions, "ec2_launch_template_id")

	assert.NotEmpty(t, ec2AsgName)
	assert.NotEmpty(t, ec2LaunchTemplateId)

	// Verify Auto Scaling Group exists and has correct configuration
	asg := aws.GetAutoScalingGroup(t, awsRegion, ec2AsgName)
	assert.Equal(t, int64(3), asg.DesiredCapacity)
	assert.Equal(t, int64(2), asg.MinSize)
	assert.Equal(t, int64(6), asg.MaxSize)

	// Wait for instances to be running
	aws.WaitForCapacity(t, asg, 3, 10*time.Minute, awsRegion)

	// Test ECS Integration
	ecsClusterName := terraform.Output(t, terraformOptions, "ecs_cluster_name")
	ecsClusterArn := terraform.Output(t, terraformOptions, "ecs_cluster_arn")
	ecsServiceName := terraform.Output(t, terraformOptions, "ecs_service_name")

	assert.NotEmpty(t, ecsClusterName)
	assert.NotEmpty(t, ecsClusterArn)
	assert.NotEmpty(t, ecsServiceName)

	// Verify ECS cluster exists
	cluster := aws.GetEcsCluster(t, awsRegion, ecsClusterName)
	assert.Equal(t, ecsClusterName, cluster.ClusterName)
	assert.Equal(t, "ACTIVE", cluster.Status)

	// Test EKS Integration
	eksClusterEndpoint := terraform.Output(t, terraformOptions, "eks_cluster_endpoint")
	eksClusterSecurityGroupId := terraform.Output(t, terraformOptions, "eks_cluster_security_group_id")

	assert.NotEmpty(t, eksClusterEndpoint)
	assert.NotEmpty(t, eksClusterSecurityGroupId)

	// Test Integration Summary
	integrationSummary := terraform.OutputMap(t, terraformOptions, "integration_summary")
	
	assert.Equal(t, "10.0.0.0/16", integrationSummary["vpc_cidr"])
	assert.Equal(t, ec2InstanceProfileName, integrationSummary["ec2_instance_profile"])
	assert.Equal(t, s3BucketName, integrationSummary["s3_bucket"])
	assert.Equal(t, efsId, integrationSummary["efs_file_system"])
	assert.Equal(t, albDnsName, integrationSummary["load_balancer_dns"])

	// Verify IAM role integration
	assert.Contains(t, integrationSummary["ecs_execution_role"], "ecs-execution-role")
	assert.Contains(t, integrationSummary["ecs_task_role"], "ecs-task-role")
	assert.Contains(t, integrationSummary["eks_cluster_role"], "eks-cluster-role")
	assert.Contains(t, integrationSummary["eks_node_group_role"], "eks-node-group-role")
}

func TestModuleIAMIntegrationPatterns(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	// Test EC2 with IAM module integration
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/ec2-iam-integration",

		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
			"ami_id":     aws.GetAmazonLinuxAmi(t, awsRegion),
			"key_name":   "test-key",
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify IAM role was created and attached
	iamRoleArn := terraform.Output(t, terraformOptions, "iam_role_arn")
	iamInstanceProfileName := terraform.Output(t, terraformOptions, "iam_instance_profile_name")

	assert.NotEmpty(t, iamRoleArn)
	assert.NotEmpty(t, iamInstanceProfileName)

	// Verify role exists in AWS
	roleName := terraform.Output(t, terraformOptions, "iam_role_name")
	role := aws.GetIamRole(t, roleName)
	assert.Equal(t, roleName, role.RoleName)

	// Verify instance profile exists
	instanceProfile := aws.GetIamInstanceProfile(t, iamInstanceProfileName)
	assert.Equal(t, iamInstanceProfileName, instanceProfile.InstanceProfileName)
	assert.Len(t, instanceProfile.Roles, 1)
	assert.Equal(t, roleName, instanceProfile.Roles[0].RoleName)
}