# Example 1: Basic IAM Users and Groups
/*
module "basic_iam" {
  source = "./modules/iam"

  # Create users
  users = {
    "john.doe" = {
      create_login_profile = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
    }
    "jane.smith" = {
      create_login_profile = true
      create_access_key   = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/PowerUserAccess"
      ]
    }
  }

  # Create groups
  groups = {
    "developers" = {
      users = ["john.doe", "jane.smith"]
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
      ]
    }
    "admins" = {
      users = ["jane.smith"]
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
      ]
    }
  }

  tags = {
    Environment = "development"
    Team        = "platform"
  }
}
*/

# Example 2: Service Roles for AWS Services
/*
module "service_roles" {
  source = "./modules/iam"

  roles = {
    "ec2-instance-role" = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      description = "Role for EC2 instances with SSM and CloudWatch access"
    }

    "lambda-execution-role" = {
      assume_role_policy = local.lambda_assume_role_policy
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      ]
      inline_policies = {
        "s3-access" = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "s3:GetObject",
                "s3:PutObject"
              ]
              Resource = "arn:aws:s3:::my-lambda-bucket/*"
            }
          ]
        })
      }
      description = "Role for Lambda functions with S3 access"
    }

    "ecs-task-role" = {
      assume_role_policy = local.ecs_assume_role_policy
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      ]
      description = "Role for ECS tasks"
    }
  }

  tags = {
    Environment = "production"
    Purpose     = "service-roles"
  }
}
*/

# Example 3: Custom Policies and Cross-Account Access
/*
module "custom_policies" {
  source = "./modules/iam"

  # Custom policies
  policies = {
    "s3-bucket-access" = {
      description = "Access to specific S3 buckets"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:ListBucket",
              "s3:GetBucketLocation"
            ]
            Resource = [
              "arn:aws:s3:::my-app-bucket",
              "arn:aws:s3:::my-logs-bucket"
            ]
          },
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = [
              "arn:aws:s3:::my-app-bucket/*",
              "arn:aws:s3:::my-logs-bucket/*"
            ]
          }
        ]
      })
    }

    "cloudwatch-metrics" = {
      description = "CloudWatch metrics access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "cloudwatch:PutMetricData",
              "cloudwatch:GetMetricStatistics",
              "cloudwatch:ListMetrics"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }

  # Cross-account access role
  roles = {
    "cross-account-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              AWS = "arn:aws:iam::123456789012:root"
            }
            Action = "sts:AssumeRole"
            Condition = {
              StringEquals = {
                "sts:ExternalId" = "unique-external-id"
              }
            }
          }
        ]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      description = "Role for cross-account access"
    }
  }

  # Application user with custom policies
  users = {
    "app-user" = {
      create_access_key = true
      managed_policy_arns = [
        module.custom_policies.policy_arns["s3-bucket-access"],
        module.custom_policies.policy_arns["cloudwatch-metrics"]
      ]
    }
  }

  tags = {
    Environment = "production"
    Purpose     = "application-access"
  }
}
*/

# Example 4: OIDC Provider for GitHub Actions
/*
module "github_oidc" {
  source = "./modules/iam"

  # OIDC provider for GitHub Actions
  oidc_providers = {
    "github-actions" = {
      url = "https://token.actions.githubusercontent.com"
      client_id_list = [
        "sts.amazonaws.com"
      ]
      thumbprint_list = [
        "6938fd4d98bab03faadb97b34396831e3780aea1"
      ]
    }
  }

  # Role for GitHub Actions
  roles = {
    "github-actions-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
              StringEquals = {
                "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
              }
              StringLike = {
                "token.actions.githubusercontent.com:sub" = "repo:my-org/my-repo:*"
              }
            }
          }
        ]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonS3FullAccess",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
      ]
      description = "Role for GitHub Actions CI/CD"
    }
  }

  tags = {
    Environment = "production"
    Purpose     = "ci-cd"
  }
}

data "aws_caller_identity" "current" {}
*/

# Example 5: Complete Enterprise Setup
/*
module "enterprise_iam" {
  source = "./modules/iam"

  # Account password policy
  account_password_policy = {
    manage_password_policy         = true
    minimum_password_length        = 16
    require_lowercase_characters   = true
    require_uppercase_characters   = true
    require_numbers               = true
    require_symbols               = true
    allow_users_to_change_password = true
    max_password_age              = 90
    password_reuse_prevention     = 12
    hard_expiry                   = false
  }

  # Enterprise users
  users = {
    "admin.user" = {
      create_login_profile = true
      password_length     = 24
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
      tags = {
        Role = "Administrator"
        Team = "Platform"
      }
    }
    "developer.user" = {
      create_login_profile = true
      create_access_key   = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/PowerUserAccess"
      ]
      tags = {
        Role = "Developer"
        Team = "Engineering"
      }
    }
    "readonly.user" = {
      create_login_profile = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/ReadOnlyAccess"
      ]
      tags = {
        Role = "Auditor"
        Team = "Compliance"
      }
    }
  }

  # Enterprise groups
  groups = {
    "administrators" = {
      users = ["admin.user"]
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/IAMFullAccess"
      ]
    }
    "developers" = {
      users = ["developer.user"]
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
        "arn:aws:iam::aws:policy/AmazonS3FullAccess"
      ]
    }
    "auditors" = {
      users = ["readonly.user"]
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/SecurityAudit"
      ]
    }
  }

  # Service roles
  roles = {
    "backup-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "backup.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
      ]
      description = "Role for AWS Backup service"
    }
  }

  # Custom policies
  policies = {
    "developer-restrictions" = {
      description = "Restrictions for developer access"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Deny"
            Action = [
              "iam:*",
              "organizations:*",
              "account:*"
            ]
            Resource = "*"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "production"
    Organization = "enterprise"
    Compliance   = "required"
  }
}
*/