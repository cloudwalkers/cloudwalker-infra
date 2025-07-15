# IAM Module

This module creates comprehensive AWS Identity and Access Management (IAM) resources including users, groups, roles, policies, and identity providers with enterprise-grade security features.

## Features

### **Core IAM Resources**
- **IAM Users**: Console and programmatic access with configurable login profiles
- **IAM Groups**: User organization with policy attachments
- **IAM Roles**: Service and cross-account access with assume role policies
- **IAM Policies**: Custom and managed policy attachments
- **Instance Profiles**: EC2 instance role integration

### **Identity Providers**
- **OIDC Providers**: GitHub Actions, GitLab CI/CD integration
- **SAML Providers**: Enterprise SSO integration
- **Cross-Account Access**: Secure multi-account architectures

### **Security Features**
- **Account Password Policy**: Enterprise-grade password requirements
- **Access Key Management**: Programmatic access control
- **Permission Boundaries**: Additional security constraints
- **Inline Policies**: Fine-grained access control

### **Advanced Features**
- **Policy Validation**: Comprehensive input validation
- **Flexible Configuration**: Support for complex IAM scenarios
- **Tag Management**: Consistent resource tagging
- **Output Mapping**: Easy integration with other modules

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    IAM Account                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │    Users    │  │   Groups    │  │    Roles    │         │
│  │             │  │             │  │             │         │
│  │ • Login     │  │ • Members   │  │ • Service   │         │
│  │ • Access    │  │ • Policies  │  │ • Cross-Acc │         │
│  │   Keys      │  │             │  │ • Instance  │         │
│  │ • Policies  │  │             │  │   Profiles  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Policies  │  │ OIDC/SAML   │  │  Password   │         │
│  │             │  │ Providers   │  │   Policy    │         │
│  │ • Custom    │  │             │  │             │         │
│  │ • Managed   │  │ • GitHub    │  │ • Length    │         │
│  │ • Inline    │  │ • GitLab    │  │ • Complexity│         │
│  │             │  │ • Enterprise│  │ • Rotation  │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic IAM Setup

```hcl
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
  }

  tags = {
    Environment = "development"
    Team        = "platform"
  }
}
```

### Service Roles for AWS Services

```hcl
module "service_roles" {
  source = "./modules/iam"

  roles = {
    "ec2-instance-role" = {
      assume_role_policy      = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
          }
        ]
      })
      create_instance_profile = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      description = "Role for EC2 instances"
    }

    "lambda-execution-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              Service = "lambda.amazonaws.com"
            }
          }
        ]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      ]
      description = "Role for Lambda functions"
    }
  }
}
```

### Custom Policies and Advanced Configuration

```hcl
module "custom_iam" {
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
              "s3:GetObject",
              "s3:PutObject"
            ]
            Resource = [
              "arn:aws:s3:::my-app-bucket",
              "arn:aws:s3:::my-app-bucket/*"
            ]
          }
        ]
      })
    }
  }

  # Users with custom policies
  users = {
    "app-user" = {
      create_access_key = true
      managed_policy_arns = [
        module.custom_iam.policy_arns["s3-bucket-access"]
      ]
      inline_policies = {
        "cloudwatch-logs" = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
              ]
              Resource = "arn:aws:logs:*:*:*"
            }
          ]
        })
      }
    }
  }
}
```

### GitHub Actions OIDC Integration

```hcl
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
        "arn:aws:iam::aws:policy/AmazonS3FullAccess"
      ]
      description = "Role for GitHub Actions CI/CD"
    }
  }
}

data "aws_caller_identity" "current" {}
```

### Enterprise Password Policy

```hcl
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

  # Enterprise users with strong policies
  users = {
    "admin.user" = {
      create_login_profile = true
      password_length     = 24
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
    }
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| users | Map of IAM users to create | `map(object)` | `{}` | no |
| groups | Map of IAM groups to create | `map(object)` | `{}` | no |
| roles | Map of IAM roles to create | `map(object)` | `{}` | no |
| policies | Map of IAM policies to create | `map(object)` | `{}` | no |
| oidc_providers | Map of OIDC identity providers | `map(object)` | `{}` | no |
| saml_providers | Map of SAML identity providers | `map(object)` | `{}` | no |
| account_password_policy | Account password policy configuration | `object` | `{}` | no |
| tags | A map of tags to assign to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| users | Map of IAM users created |
| groups | Map of IAM groups created |
| roles | Map of IAM roles created |
| policies | Map of IAM policies created |
| instance_profiles | Map of IAM instance profiles created |
| role_arns | Map of role names to ARNs |
| policy_arns | Map of policy names to ARNs |
| user_arns | Map of user names to ARNs |
| oidc_providers | Map of OIDC providers created |
| saml_providers | Map of SAML providers created |

## User Configuration

Users support comprehensive configuration options:

```hcl
users = {
  "username" = {
    path                    = "/"                    # IAM path
    force_destroy           = false                  # Force delete user
    create_login_profile    = true                   # Console access
    password_reset_required = true                   # Force password reset
    password_length         = 20                     # Password length
    create_access_key       = false                  # Programmatic access
    access_key_status       = "Active"              # Access key status
    managed_policy_arns     = []                     # AWS managed policies
    inline_policies         = {}                     # Custom inline policies
    tags                    = {}                     # User-specific tags
  }
}
```

## Group Configuration

Groups provide user organization and policy management:

```hcl
groups = {
  "groupname" = {
    path                = "/"                        # IAM path
    users               = ["user1", "user2"]        # Group members
    managed_policy_arns = []                         # AWS managed policies
    inline_policies     = {}                         # Custom inline policies
    tags                = {}                         # Group-specific tags
  }
}
```

## Role Configuration

Roles support service and cross-account access:

```hcl
roles = {
  "rolename" = {
    path                         = "/"               # IAM path
    description                  = ""                # Role description
    assume_role_policy           = "policy_json"     # Trust policy
    max_session_duration         = 3600              # Session duration
    permissions_boundary         = null              # Permission boundary
    force_detach_policies        = false             # Force policy detach
    create_instance_profile      = false             # Create EC2 profile
    managed_policy_arns          = []                # AWS managed policies
    inline_policies              = {}                # Inline policies (in role)
    additional_inline_policies   = {}                # Additional inline policies
    tags                         = {}                # Role-specific tags
  }
}
```

## Security Best Practices

### **Password Policy**
- Minimum 14 characters (recommended 16+)
- Require uppercase, lowercase, numbers, symbols
- 90-day maximum age
- 12 password history
- Allow user password changes

### **Access Keys**
- Create only when necessary
- Rotate regularly
- Use IAM roles instead when possible
- Monitor usage with CloudTrail

### **Roles vs Users**
- Prefer roles for applications and services
- Use cross-account roles for multi-account access
- Implement least privilege principle
- Regular access reviews

### **Policy Management**
- Use managed policies when possible
- Custom policies for specific requirements
- Regular policy audits
- Version control for policy changes

## Integration Examples

### With EC2 Module
```hcl
module "iam" {
  source = "./modules/iam"
  
  roles = {
    "ec2-role" = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }
  }
}

module "ec2" {
  source = "./modules/ec2"
  
  iam_instance_profile_name = module.iam.instance_profiles["ec2-role"].name
  # ... other configuration
}
```

### With ECS Module
```hcl
module "iam" {
  source = "./modules/iam"
  
  roles = {
    "ecs-execution-role" = {
      assume_role_policy = local.ecs_assume_role_policy
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      ]
    }
  }
}

module "ecs" {
  source = "./modules/ecs"
  
  execution_role_arn = module.iam.role_arns["ecs-execution-role"]
  # ... other configuration
}
```

## Common Assume Role Policies

The module provides common assume role policies:

```hcl
# Available via outputs
module.iam.common_assume_role_policies.ec2     # EC2 service
module.iam.common_assume_role_policies.lambda  # Lambda service  
module.iam.common_assume_role_policies.ecs     # ECS tasks
```

## Compliance and Auditing

- **CloudTrail Integration**: All IAM actions logged
- **Access Analyzer**: Identify unused access
- **Credential Reports**: Regular access reviews
- **Policy Simulator**: Test permissions before deployment
- **Tag-based Access Control**: Implement attribute-based access

## Cost Considerations

- IAM resources are free
- CloudTrail logging may incur costs
- Regular cleanup of unused resources
- Monitor access key usage
- Implement lifecycle policies for temporary access