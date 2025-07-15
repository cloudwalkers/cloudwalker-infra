# User Outputs
output "users" {
  description = "Map of IAM users created"
  value = {
    for k, v in aws_iam_user.this : k => {
      name         = v.name
      arn          = v.arn
      unique_id    = v.unique_id
      path         = v.path
      tags         = v.tags
    }
  }
}

output "user_login_profiles" {
  description = "Map of IAM user login profiles created"
  value = {
    for k, v in aws_iam_user_login_profile.this : k => {
      user                    = v.user
      encrypted_password      = v.encrypted_password
      key_fingerprint         = v.key_fingerprint
      password_reset_required = v.password_reset_required
    }
  }
  sensitive = true
}

output "user_access_keys" {
  description = "Map of IAM user access keys created"
  value = {
    for k, v in aws_iam_access_key.this : k => {
      id     = v.id
      user   = v.user
      status = v.status
      secret = v.secret
    }
  }
  sensitive = true
}

# Group Outputs
output "groups" {
  description = "Map of IAM groups created"
  value = {
    for k, v in aws_iam_group.this : k => {
      name      = v.name
      arn       = v.arn
      unique_id = v.unique_id
      path      = v.path
    }
  }
}

output "group_memberships" {
  description = "Map of IAM group memberships"
  value = {
    for k, v in aws_iam_group_membership.this : k => {
      name  = v.name
      group = v.group
      users = v.users
    }
  }
}

# Role Outputs
output "roles" {
  description = "Map of IAM roles created"
  value = {
    for k, v in aws_iam_role.this : k => {
      name                 = v.name
      arn                  = v.arn
      unique_id            = v.unique_id
      path                 = v.path
      description          = v.description
      max_session_duration = v.max_session_duration
      tags                 = v.tags
    }
  }
}

output "instance_profiles" {
  description = "Map of IAM instance profiles created"
  value = {
    for k, v in aws_iam_instance_profile.this : k => {
      name      = v.name
      arn       = v.arn
      unique_id = v.unique_id
      path      = v.path
      role      = v.role
      tags      = v.tags
    }
  }
}

# Policy Outputs
output "policies" {
  description = "Map of IAM policies created"
  value = {
    for k, v in aws_iam_policy.this : k => {
      name        = v.name
      arn         = v.arn
      policy_id   = v.policy_id
      path        = v.path
      description = v.description
      tags        = v.tags
    }
  }
}

# Identity Provider Outputs
output "oidc_providers" {
  description = "Map of OIDC identity providers created"
  value = {
    for k, v in aws_iam_openid_connect_provider.this : k => {
      arn             = v.arn
      url             = v.url
      client_id_list  = v.client_id_list
      thumbprint_list = v.thumbprint_list
      tags            = v.tags
    }
  }
}

output "saml_providers" {
  description = "Map of SAML identity providers created"
  value = {
    for k, v in aws_iam_saml_provider.this : k => {
      name                   = v.name
      arn                    = v.arn
      saml_metadata_document = v.saml_metadata_document
      tags                   = v.tags
    }
  }
}

# Convenience Outputs
output "role_arns" {
  description = "Map of role names to ARNs"
  value = {
    for k, v in aws_iam_role.this : k => v.arn
  }
}

output "policy_arns" {
  description = "Map of policy names to ARNs"
  value = {
    for k, v in aws_iam_policy.this : k => v.arn
  }
}

output "user_arns" {
  description = "Map of user names to ARNs"
  value = {
    for k, v in aws_iam_user.this : k => v.arn
  }
}

output "group_arns" {
  description = "Map of group names to ARNs"
  value = {
    for k, v in aws_iam_group.this : k => v.arn
  }
}

# Common assume role policies for reference
output "common_assume_role_policies" {
  description = "Common assume role policies for reference"
  value = {
    ec2    = local.ec2_assume_role_policy
    lambda = local.lambda_assume_role_policy
    ecs    = local.ecs_assume_role_policy
  }
}