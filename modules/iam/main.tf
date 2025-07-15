# ============================================================================
# IAM USER RESOURCES
# ============================================================================
# IAM users provide individual identities for people or applications
# Each user can have policies, access keys, and login profiles attached
# Users are the foundation of AWS identity and access management
# ============================================================================

# IAM Users
# Creates individual user accounts for human users or applications
# Each user gets a unique identity within the AWS account
# Users can be assigned to groups and have policies attached directly
resource "aws_iam_user" "this" {
  for_each = var.users

  name          = each.key
  path          = each.value.path
  force_destroy = each.value.force_destroy

  tags = merge(var.tags, each.value.tags, {
    Name      = each.key
    Purpose   = "IAM user for identity and access management"
    ManagedBy = "terraform"
    Module    = "iam"
  })
}

# IAM User Login Profiles
# Creates console access credentials for users who need AWS Management Console access
# Generates temporary passwords that must be changed on first login
# Only created for users where create_login_profile is true
resource "aws_iam_user_login_profile" "this" {
  for_each = {
    for k, v in var.users : k => v
    if v.create_login_profile
  }

  user                    = aws_iam_user.this[each.key].name
  password_reset_required = each.value.password_reset_required
  password_length         = each.value.password_length

  # Lifecycle management to prevent constant password resets
  lifecycle {
    ignore_changes = [password_reset_required]
  }
}

# IAM Access Keys
# Creates programmatic access credentials for users who need API/CLI access
# Provides Access Key ID and Secret Access Key for AWS SDK/CLI authentication
# Only created for users where create_access_key is true
resource "aws_iam_access_key" "this" {
  for_each = {
    for k, v in var.users : k => v
    if v.create_access_key
  }

  user   = aws_iam_user.this[each.key].name
  status = each.value.access_key_status
}

# ============================================================================
# IAM GROUP RESOURCES
# ============================================================================
# IAM groups provide a way to organize users and apply policies collectively
# Groups simplify permission management by allowing policy attachment to groups
# rather than individual users, following the principle of least privilege
# ============================================================================

# IAM Groups
# Creates logical collections of users for easier permission management
# Groups don't have credentials themselves but serve as policy attachment points
# Users inherit permissions from all groups they belong to
resource "aws_iam_group" "this" {
  for_each = var.groups

  name = each.key
  path = each.value.path

  tags = merge(var.tags, each.value.tags, {
    Name      = each.key
    Purpose   = "IAM group for organizing users and permissions"
    ManagedBy = "terraform"
    Module    = "iam"
  })
}

# IAM Group Memberships
# Defines which users belong to which groups
# Users can belong to multiple groups and inherit permissions from all
# Group membership is managed separately to allow flexible user-group relationships
resource "aws_iam_group_membership" "this" {
  for_each = var.groups

  name  = "${each.key}-membership"
  users = each.value.users
  group = aws_iam_group.this[each.key].name

  # Ensure users exist before adding them to groups
  depends_on = [aws_iam_user.this]
}

# ============================================================================
# IAM ROLE RESOURCES
# ============================================================================
# IAM roles provide temporary credentials for AWS services and cross-account access
# Roles are assumed by trusted entities and provide secure access without long-term keys
# Essential for service-to-service authentication and cross-account scenarios
# ============================================================================

# IAM Roles
# Creates roles that can be assumed by AWS services, users, or external identities
# Roles provide temporary credentials and are the preferred method for service authentication
# Each role has a trust policy defining who can assume it and permission policies defining what it can do
resource "aws_iam_role" "this" {
  for_each = var.roles

  name                  = each.key
  path                  = each.value.path
  description           = each.value.description
  assume_role_policy    = each.value.assume_role_policy  # Trust policy - who can assume this role
  max_session_duration  = each.value.max_session_duration  # Maximum session duration (1-12 hours)
  permissions_boundary  = each.value.permissions_boundary  # Optional permissions boundary for additional security
  force_detach_policies = each.value.force_detach_policies  # Force detach policies during deletion

  # Inline Policies
  # Policies embedded directly in the role definition
  # Deleted automatically when the role is deleted
  dynamic "inline_policy" {
    for_each = each.value.inline_policies
    content {
      name   = inline_policy.key
      policy = inline_policy.value
    }
  }

  tags = merge(var.tags, each.value.tags, {
    Name      = each.key
    Purpose   = "IAM role for ${each.value.description}"
    ManagedBy = "terraform"
    Module    = "iam"
  })
}

# IAM Instance Profiles
# Container for IAM roles that can be attached to EC2 instances
# Instance profiles allow EC2 instances to assume IAM roles and access AWS services
# Only created for roles where create_instance_profile is true
resource "aws_iam_instance_profile" "this" {
  for_each = {
    for k, v in var.roles : k => v
    if v.create_instance_profile
  }

  name = each.key
  path = var.roles[each.key].path
  role = aws_iam_role.this[each.key].name

  tags = merge(var.tags, var.roles[each.key].tags, {
    Name      = each.key
    Purpose   = "Instance profile for EC2 role ${each.key}"
    ManagedBy = "terraform"
    Module    = "iam"
  })
}

# ============================================================================
# IAM POLICY RESOURCES
# ============================================================================
# Custom IAM policies define specific permissions for AWS resources and actions
# Policies are JSON documents that specify allowed or denied actions
# Can be attached to users, groups, or roles for flexible permission management
# ============================================================================

# IAM Policies
# Creates custom policies with specific permissions for your applications
# Policies define what actions are allowed or denied on which AWS resources
# More granular than AWS managed policies, tailored to specific use cases
resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = each.key
  path        = each.value.path
  description = each.value.description
  policy      = each.value.policy

  tags = merge(var.tags, each.value.tags, {
    Name      = each.key
    Purpose   = "Custom IAM policy: ${each.value.description}"
    ManagedBy = "terraform"
    Module    = "iam"
  })
}

# ============================================================================
# POLICY ATTACHMENT RESOURCES
# ============================================================================
# Policy attachments link policies to users, groups, and roles
# Managed policies are AWS or customer-managed standalone policies
# Inline policies are embedded directly in the identity
# ============================================================================

# User Managed Policy Attachments
# Attaches AWS managed or customer-managed policies to users
# Managed policies can be reused across multiple identities
# Provides centralized policy management and versioning
resource "aws_iam_user_policy_attachment" "managed" {
  for_each = local.user_policy_attachments

  user       = each.value.user
  policy_arn = each.value.policy_arn

  depends_on = [aws_iam_user.this, aws_iam_policy.this]
}

# User Inline Policies
# Embeds policies directly in user definitions
# Inline policies are deleted when the user is deleted
# Used for user-specific permissions that won't be reused
resource "aws_iam_user_policy" "inline" {
  for_each = local.user_inline_policies

  name   = each.value.policy_name
  user   = each.value.user
  policy = each.value.policy

  depends_on = [aws_iam_user.this]
}

# Group Managed Policy Attachments
# Attaches AWS managed or customer-managed policies to groups
# All group members inherit these permissions
# Simplifies permission management for multiple users
resource "aws_iam_group_policy_attachment" "managed" {
  for_each = local.group_policy_attachments

  group      = each.value.group
  policy_arn = each.value.policy_arn

  depends_on = [aws_iam_group.this, aws_iam_policy.this]
}

# Group Inline Policies
# Embeds policies directly in group definitions
# Inline policies are deleted when the group is deleted
# Used for group-specific permissions that won't be reused
resource "aws_iam_group_policy" "inline" {
  for_each = local.group_inline_policies

  name   = each.value.policy_name
  group  = each.value.group
  policy = each.value.policy

  depends_on = [aws_iam_group.this]
}

# Role Managed Policy Attachments
# Attaches AWS managed or customer-managed policies to roles
# Enables roles to access AWS services and resources
# Preferred method for service-to-service authentication
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.role_policy_attachments

  role       = each.value.role
  policy_arn = each.value.policy_arn

  depends_on = [aws_iam_role.this, aws_iam_policy.this]
}

# Role Inline Policies
# Embeds policies directly in role definitions
# Inline policies are deleted when the role is deleted
# Used for role-specific permissions that won't be reused
resource "aws_iam_role_policy" "inline" {
  for_each = local.role_inline_policies

  name   = each.value.policy_name
  role   = each.value.role
  policy = each.value.policy

  depends_on = [aws_iam_role.this]
}

# ============================================================================
# IDENTITY PROVIDER RESOURCES
# ============================================================================
# Identity providers enable federated access to AWS from external identity systems
# OIDC providers support modern web identity federation (GitHub Actions, etc.)
# SAML providers support enterprise identity systems (Active Directory, etc.)
# ============================================================================

# OIDC Identity Providers
# Enables federated access from OpenID Connect compatible identity providers
# Commonly used for CI/CD systems like GitHub Actions, GitLab CI, etc.
# Allows external systems to assume AWS roles without long-term credentials
resource "aws_iam_openid_connect_provider" "this" {
  for_each = var.oidc_providers

  url             = each.value.url              # Identity provider URL
  client_id_list  = each.value.client_id_list  # List of client IDs (audiences)
  thumbprint_list = each.value.thumbprint_list # Server certificate thumbprints

  tags = merge(var.tags, each.value.tags, {
    Name      = each.key
    Purpose   = "OIDC identity provider for federated access"
    ManagedBy = "terraform"
    Module    = "iam"
  })
}

# SAML Identity Providers
# Enables federated access from SAML 2.0 compatible identity providers
# Commonly used for enterprise SSO solutions like Active Directory Federation Services
# Allows users to access AWS using their corporate credentials
resource "aws_iam_saml_provider" "this" {
  for_each = var.saml_providers

  name                   = each.key
  saml_metadata_document = each.value.saml_metadata_document  # SAML metadata XML

  tags = merge(var.tags, each.value.tags, {
    Name      = each.key
    Purpose   = "SAML identity provider for enterprise SSO"
    ManagedBy = "terraform"
    Module    = "iam"
  })
}

# ============================================================================
# ACCOUNT SECURITY POLICY
# ============================================================================
# Account-level password policy enforces security standards for all IAM users
# Defines password complexity, rotation, and reuse requirements
# Essential for compliance and security best practices
# ============================================================================

# Account Password Policy
# Enforces password security requirements for all IAM users in the account
# Defines minimum length, complexity requirements, and rotation policies
# Critical for maintaining security compliance and preventing weak passwords
resource "aws_iam_account_password_policy" "this" {
  count = var.account_password_policy.manage_password_policy ? 1 : 0

  # Password Length and Complexity
  minimum_password_length        = var.account_password_policy.minimum_password_length        # Minimum 8-128 characters
  require_lowercase_characters   = var.account_password_policy.require_lowercase_characters   # Require a-z
  require_uppercase_characters   = var.account_password_policy.require_uppercase_characters   # Require A-Z
  require_numbers               = var.account_password_policy.require_numbers               # Require 0-9
  require_symbols               = var.account_password_policy.require_symbols               # Require special characters

  # Password Management
  allow_users_to_change_password = var.account_password_policy.allow_users_to_change_password # Users can change own passwords
  max_password_age              = var.account_password_policy.max_password_age              # Maximum password age in days
  password_reuse_prevention     = var.account_password_policy.password_reuse_prevention     # Number of previous passwords to remember
  hard_expiry                   = var.account_password_policy.hard_expiry                   # Prevent login after password expires
}