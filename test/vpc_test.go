package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
	t.Parallel()

	// Pick a random AWS region to test in
	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	
	// Generate a random name prefix to avoid conflicts
	namePrefix := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Path to the Terraform code
		TerraformDir: "../examples/vpc-basic",

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"name_prefix":             namePrefix,
			"vpc_cidr_block":          "10.0.0.0/16",
			"public_subnet_cidrs":     []string{"10.0.1.0/24", "10.0.2.0/24"},
			"private_subnet_cidrs":    []string{"10.0.10.0/24", "10.0.20.0/24"},
			"allowed_ips":             []string{"0.0.0.0/0"},
		},

		// Environment variables to set when running Terraform
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// Clean up resources with "terraform destroy" at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply"
	terraform.InitAndApply(t, terraformOptions)

	// Run `terraform output` to get the values of output variables
	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")
	internetGatewayId := terraform.Output(t, terraformOptions, "internet_gateway_id")

	// Verify the VPC exists and has the expected properties
	vpc := aws.GetVpcById(t, vpcId, awsRegion)
	assert.Equal(t, "10.0.0.0/16", vpc.CidrBlock)
	assert.True(t, vpc.EnableDnsHostnames)
	assert.True(t, vpc.EnableDnsSupport)

	// Verify we have the expected number of subnets
	assert.Equal(t, 2, len(publicSubnetIds))
	assert.Equal(t, 2, len(privateSubnetIds))

	// Verify public subnets have the correct properties
	for _, subnetId := range publicSubnetIds {
		subnet := aws.GetSubnetById(t, subnetId, awsRegion)
		assert.Equal(t, vpcId, subnet.VpcId)
		assert.True(t, subnet.MapPublicIpOnLaunch)
	}

	// Verify private subnets have the correct properties
	for _, subnetId := range privateSubnetIds {
		subnet := aws.GetSubnetById(t, subnetId, awsRegion)
		assert.Equal(t, vpcId, subnet.VpcId)
		assert.False(t, subnet.MapPublicIpOnLaunch)
	}

	// Verify Internet Gateway exists
	igw := aws.GetInternetGatewayById(t, internetGatewayId, awsRegion)
	assert.Equal(t, vpcId, igw.VpcId)
}

func TestVPCModuleWithCustomCIDR(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/vpc-custom",

		Vars: map[string]interface{}{
			"name_prefix":             namePrefix,
			"vpc_cidr_block":          "172.16.0.0/16",
			"public_subnet_cidrs":     []string{"172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"},
			"private_subnet_cidrs":    []string{"172.16.10.0/24", "172.16.20.0/24", "172.16.30.0/24"},
			"allowed_ips":             []string{"172.16.0.0/16"},
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	vpcId := terraform.Output(t, terraformOptions, "vpc_id")
	publicSubnetIds := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnetIds := terraform.OutputList(t, terraformOptions, "private_subnet_ids")

	// Verify custom CIDR block
	vpc := aws.GetVpcById(t, vpcId, awsRegion)
	assert.Equal(t, "172.16.0.0/16", vpc.CidrBlock)

	// Verify we have 3 subnets of each type
	assert.Equal(t, 3, len(publicSubnetIds))
	assert.Equal(t, 3, len(privateSubnetIds))
}