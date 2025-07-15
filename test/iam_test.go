package test

import (
	"encoding/json"
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestIAMModuleBasic(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/iam-basic",

		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
			"users": map[string]interface{}{
				namePrefix + "-test-user": map[string]interface{}{
					"create_login_profile": false,
					"create_access_key":   true,
					"managed_policy_arns": []string{
						"arn:aws:iam::aws:policy/ReadOnlyAccess",
					},
				},
			},
			"groups": map[string]interface{}{
				namePrefix + "-test-group": map[string]interface{}{
					"users": []string{namePrefix + "-test-user"},
					"managed_policy_arns": []string{
						"arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
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

	// Test outputs
	users := terraform.OutputMap(t, terraformOptions, "users")
	groups := terraform.OutputMap(t, terraformOptions, "groups")
	userArns := terraform.OutputMap(t, terraformOptions, "user_arns")
	groupArns := terraform.OutputMap(t, terraformOptions, "group_arns")

	// Verify user was created
	expectedUserName := namePrefix + "-test-user"
	assert.Contains(t, users, expectedUserName)
	assert.Contains(t, userArns, expectedUserName)

	// Verify group was created
	expectedGroupName := namePrefix + "-test-group"
	assert.Contains(t, groups, expectedGroupName)
	assert.Contains(t, groupArns, expectedGroupName)

	// Verify user exists in AWS
	user := aws.GetIamUser(t, expectedUserName)
	assert.Equal(t, expectedUserName, user.UserName)
	assert.Equal(t, "/", user.Path)

	// Verify group exists in AWS
	group := aws.GetIamGroup(t, expectedGroupName)
	assert.Equal(t, expectedGroupName, group.GroupName)
	assert.Equal(t, "/", group.Path)

	// Verify group membership
	groupUsers := aws.GetIamUsersInGroup(t, expectedGroupName)
	assert.Len(t, groupUsers, 1)
	assert.Equal(t, expectedUserName, groupUsers[0].UserName)
}

func TestIAMModuleRoles(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	ec2AssumeRolePolicy := map[string]interface{}{
		"Version": "2012-10-17",
		"Statement": []map[string]interface{}{
			{
				"Action": "sts:AssumeRole",
				"Effect": "Allow",
				"Principal": map[string]interface{}{
					"Service": "ec2.amazonaws.com",
				},
			},
		},
	}

	ec2AssumeRolePolicyJSON, _ := json.Marshal(ec2AssumeRolePolicy)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/iam-roles",

		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
			"roles": map[string]interface{}{
				namePrefix + "-ec2-role": map[string]interface{}{
					"assume_role_policy":      string(ec2AssumeRolePolicyJSON),
					"create_instance_profile": true,
					"description":            "Test EC2 role",
					"managed_policy_arns": []string{
						"arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
					},
				},
				namePrefix + "-lambda-role": map[string]interface{}{
					"assume_role_policy": `{
						"Version": "2012-10-17",
						"Statement": [
							{
								"Action": "sts:AssumeRole",
								"Effect": "Allow",
								"Principal": {
									"Service": "lambda.amazonaws.com"
								}
							}
						]
					}`,
					"description": "Test Lambda role",
					"managed_policy_arns": []string{
						"arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
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

	// Test outputs
	roles := terraform.OutputMap(t, terraformOptions, "roles")
	roleArns := terraform.OutputMap(t, terraformOptions, "role_arns")
	instanceProfiles := terraform.OutputMap(t, terraformOptions, "instance_profiles")

	// Verify EC2 role was created
	expectedEC2RoleName := namePrefix + "-ec2-role"
	assert.Contains(t, roles, expectedEC2RoleName)
	assert.Contains(t, roleArns, expectedEC2RoleName)
	assert.Contains(t, instanceProfiles, expectedEC2RoleName)

	// Verify Lambda role was created
	expectedLambdaRoleName := namePrefix + "-lambda-role"
	assert.Contains(t, roles, expectedLambdaRoleName)
	assert.Contains(t, roleArns, expectedLambdaRoleName)

	// Verify roles exist in AWS
	ec2Role := aws.GetIamRole(t, expectedEC2RoleName)
	assert.Equal(t, expectedEC2RoleName, ec2Role.RoleName)
	assert.Equal(t, "Test EC2 role", ec2Role.Description)
	assert.Equal(t, "/", ec2Role.Path)

	lambdaRole := aws.GetIamRole(t, expectedLambdaRoleName)
	assert.Equal(t, expectedLambdaRoleName, lambdaRole.RoleName)
	assert.Equal(t, "Test Lambda role", lambdaRole.Description)

	// Verify instance profile exists
	instanceProfile := aws.GetIamInstanceProfile(t, expectedEC2RoleName)
	assert.Equal(t, expectedEC2RoleName, instanceProfile.InstanceProfileName)
	assert.Len(t, instanceProfile.Roles, 1)
	assert.Equal(t, expectedEC2RoleName, instanceProfile.Roles[0].RoleName)
}

func TestIAMModuleCustomPolicies(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	customPolicy := map[string]interface{}{
		"Version": "2012-10-17",
		"Statement": []map[string]interface{}{
			{
				"Effect": "Allow",
				"Action": []string{
					"s3:ListBucket",
					"s3:GetObject",
				},
				"Resource": []string{
					"arn:aws:s3:::test-bucket",
					"arn:aws:s3:::test-bucket/*",
				},
			},
		},
	}

	customPolicyJSON, _ := json.Marshal(customPolicy)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/iam-policies",

		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
			"policies": map[string]interface{}{
				namePrefix + "-s3-policy": map[string]interface{}{
					"description": "Test S3 access policy",
					"policy":      string(customPolicyJSON),
				},
			},
			"users": map[string]interface{}{
				namePrefix + "-policy-user": map[string]interface{}{
					"create_access_key": true,
					"inline_policies": map[string]interface{}{
						"cloudwatch-access": `{
							"Version": "2012-10-17",
							"Statement": [
								{
									"Effect": "Allow",
									"Action": [
										"cloudwatch:PutMetricData",
										"cloudwatch:GetMetricStatistics"
									],
									"Resource": "*"
								}
							]
						}`,
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

	// Test outputs
	policies := terraform.OutputMap(t, terraformOptions, "policies")
	policyArns := terraform.OutputMap(t, terraformOptions, "policy_arns")
	users := terraform.OutputMap(t, terraformOptions, "users")

	// Verify custom policy was created
	expectedPolicyName := namePrefix + "-s3-policy"
	assert.Contains(t, policies, expectedPolicyName)
	assert.Contains(t, policyArns, expectedPolicyName)

	// Verify user was created
	expectedUserName := namePrefix + "-policy-user"
	assert.Contains(t, users, expectedUserName)

	// Verify policy exists in AWS
	policyArn := policyArns[expectedPolicyName]
	policy := aws.GetIamPolicy(t, policyArn)
	assert.Equal(t, expectedPolicyName, policy.PolicyName)
	assert.Equal(t, "Test S3 access policy", policy.Description)
	assert.Equal(t, "/", policy.Path)

	// Verify user exists in AWS
	user := aws.GetIamUser(t, expectedUserName)
	assert.Equal(t, expectedUserName, user.UserName)

	// Verify user has inline policy
	userPolicies := aws.GetIamUserPolicies(t, expectedUserName)
	assert.Contains(t, userPolicies, "cloudwatch-access")
}

func TestIAMModuleOIDCProvider(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/iam-oidc",

		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
			"oidc_providers": map[string]interface{}{
				"github-actions": map[string]interface{}{
					"url": "https://token.actions.githubusercontent.com",
					"client_id_list": []string{
						"sts.amazonaws.com",
					},
					"thumbprint_list": []string{
						"6938fd4d98bab03faadb97b34396831e3780aea1",
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

	// Test outputs
	oidcProviders := terraform.OutputMap(t, terraformOptions, "oidc_providers")

	// Verify OIDC provider was created
	assert.Contains(t, oidcProviders, "github-actions")

	// Get the provider ARN from outputs
	providerData := oidcProviders["github-actions"]
	assert.NotEmpty(t, providerData)
}

func TestIAMModulePasswordPolicy(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/iam-password-policy",

		Vars: map[string]interface{}{
			"account_password_policy": map[string]interface{}{
				"manage_password_policy":         true,
				"minimum_password_length":        16,
				"require_lowercase_characters":   true,
				"require_uppercase_characters":   true,
				"require_numbers":               true,
				"require_symbols":               true,
				"allow_users_to_change_password": true,
				"max_password_age":              90,
				"password_reuse_prevention":     12,
				"hard_expiry":                   false,
			},
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify password policy was applied
	passwordPolicy := aws.GetAccountPasswordPolicy(t)
	assert.Equal(t, 16, passwordPolicy.MinimumPasswordLength)
	assert.True(t, passwordPolicy.RequireLowercaseCharacters)
	assert.True(t, passwordPolicy.RequireUppercaseCharacters)
	assert.True(t, passwordPolicy.RequireNumbers)
	assert.True(t, passwordPolicy.RequireSymbols)
	assert.True(t, passwordPolicy.AllowUsersToChangePassword)
	assert.Equal(t, 90, passwordPolicy.MaxPasswordAge)
	assert.Equal(t, 12, passwordPolicy.PasswordReusePrevention)
	assert.False(t, passwordPolicy.HardExpiry)
}

func TestIAMModuleValidation(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)

	// Test invalid user name (should fail validation)
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/iam-validation",

		Vars: map[string]interface{}{
			"users": map[string]interface{}{
				"invalid@user@name": map[string]interface{}{
					"create_login_profile": false,
				},
			},
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// This should fail during plan due to validation
	_, err := terraform.InitAndPlanE(t, terraformOptions)
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "must contain only alphanumeric characters")
}

func TestIAMModuleComplexScenario(t *testing.T) {
	t.Parallel()

	awsRegion := aws.GetRandomStableRegion(t, nil, nil)
	namePrefix := random.UniqueId()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/iam-complex",

		Vars: map[string]interface{}{
			"name_prefix": namePrefix,
			// Complex scenario with users, groups, roles, and policies
			"users": map[string]interface{}{
				namePrefix + "-admin": map[string]interface{}{
					"create_login_profile": false,
					"create_access_key":   true,
					"managed_policy_arns": []string{
						"arn:aws:iam::aws:policy/PowerUserAccess",
					},
				},
				namePrefix + "-developer": map[string]interface{}{
					"create_login_profile": false,
					"managed_policy_arns": []string{
						"arn:aws:iam::aws:policy/ReadOnlyAccess",
					},
				},
			},
			"groups": map[string]interface{}{
				namePrefix + "-admins": map[string]interface{}{
					"users": []string{namePrefix + "-admin"},
					"managed_policy_arns": []string{
						"arn:aws:iam::aws:policy/IAMReadOnlyAccess",
					},
				},
				namePrefix + "-developers": map[string]interface{}{
					"users": []string{namePrefix + "-developer"},
				},
			},
			"roles": map[string]interface{}{
				namePrefix + "-service-role": map[string]interface{}{
					"assume_role_policy": `{
						"Version": "2012-10-17",
						"Statement": [
							{
								"Action": "sts:AssumeRole",
								"Effect": "Allow",
								"Principal": {
									"Service": "ec2.amazonaws.com"
								}
							}
						]
					}`,
					"create_instance_profile": true,
					"description":            "Complex test service role",
				},
			},
		},

		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify all resources were created
	users := terraform.OutputMap(t, terraformOptions, "users")
	groups := terraform.OutputMap(t, terraformOptions, "groups")
	roles := terraform.OutputMap(t, terraformOptions, "roles")
	instanceProfiles := terraform.OutputMap(t, terraformOptions, "instance_profiles")

	// Verify users
	assert.Contains(t, users, namePrefix+"-admin")
	assert.Contains(t, users, namePrefix+"-developer")

	// Verify groups
	assert.Contains(t, groups, namePrefix+"-admins")
	assert.Contains(t, groups, namePrefix+"-developers")

	// Verify roles
	assert.Contains(t, roles, namePrefix+"-service-role")
	assert.Contains(t, instanceProfiles, namePrefix+"-service-role")

	// Verify resources exist in AWS
	adminUser := aws.GetIamUser(t, namePrefix+"-admin")
	assert.Equal(t, namePrefix+"-admin", adminUser.UserName)

	adminGroup := aws.GetIamGroup(t, namePrefix+"-admins")
	assert.Equal(t, namePrefix+"-admins", adminGroup.GroupName)

	serviceRole := aws.GetIamRole(t, namePrefix+"-service-role")
	assert.Equal(t, namePrefix+"-service-role", serviceRole.RoleName)
	assert.Equal(t, "Complex test service role", serviceRole.Description)
}