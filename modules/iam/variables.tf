# IAM Users Configuration
variable "users" {
  description = "Map of IAM users to create"
  type = map(object({
    path                    = optional(string, "/")
    force_destroy           = optional(bool, false)
    create_login_profile    = optional(bool, false)
    password_reset_required = optional(bool, true)
    password_length         = optional(number, 20)
    create_access_key       = optional(bool, false)
    access_key_status       = optional(string, "Active")
    managed_policy_arns     = optional(list(string), [])
    inline_policies         = optional(map(string), {})
    tags                    = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.users : can(regex("^[a-zA-Z0-9+=,.@_-]+$", k))
    ])
    error_message = "User names must contain only alphanumeric characters and +=,.@_-"
  }

  validation {
    condition = alltrue([
      for k, v in var.users : v.password_length >= 8 && v.password_length <= 128
    ])
    error_message = "Password length must be between 8 and 128 characters."
  }
}

# IAM Groups Configuration
variable "groups" {
  description = "Map of IAM groups to create"
  type = map(object({
    path                = optional(string, "/")
    users               = optional(list(string), [])
    managed_policy_arns = optional(list(string), [])
    inline_policies     = optional(map(string), {})
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.groups : can(regex("^[a-zA-Z0-9+=,.@_-]+$", k))
    ])
    error_message = "Group names must contain only alphanumeric characters and +=,.@_-"
  }
}

# IAM Roles Configuration
variable "roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    path                         = optional(string, "/")
    description                  = optional(string, "")
    assume_role_policy           = string
    max_session_duration         = optional(number, 3600)
    permissions_boundary         = optional(string, null)
    force_detach_policies        = optional(bool, false)
    create_instance_profile      = optional(bool, false)
    managed_policy_arns          = optional(list(string), [])
    inline_policies              = optional(map(string), {})
    additional_inline_policies   = optional(map(string), {})
    tags                         = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.roles : can(regex("^[a-zA-Z0-9+=,.@_-]+$", k))
    ])
    error_message = "Role names must contain only alphanumeric characters and +=,.@_-"
  }

  validation {
    condition = alltrue([
      for k, v in var.roles : v.max_session_duration >= 3600 && v.max_session_duration <= 43200
    ])
    error_message = "Max session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

# IAM Policies Configuration
variable "policies" {
  description = "Map of IAM policies to create"
  type = map(object({
    path        = optional(string, "/")
    description = optional(string, "")
    policy      = string
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.policies : can(regex("^[a-zA-Z0-9+=,.@_-]+$", k))
    ])
    error_message = "Policy names must contain only alphanumeric characters and +=,.@_-"
  }
}

# OIDC Identity Providers
variable "oidc_providers" {
  description = "Map of OIDC identity providers to create"
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
    tags            = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.oidc_providers : can(regex("^https://", v.url))
    ])
    error_message = "OIDC provider URLs must start with https://"
  }
}

# SAML Identity Providers
variable "saml_providers" {
  description = "Map of SAML identity providers to create"
  type = map(object({
    saml_metadata_document = string
    tags                   = optional(map(string), {})
  }))
  default = {}
}

# Common Tags
variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

# Account Password Policy
variable "account_password_policy" {
  description = "Account password policy configuration"
  type = object({
    manage_password_policy         = optional(bool, false)
    minimum_password_length        = optional(number, 14)
    require_lowercase_characters   = optional(bool, true)
    require_uppercase_characters   = optional(bool, true)
    require_numbers               = optional(bool, true)
    require_symbols               = optional(bool, true)
    allow_users_to_change_password = optional(bool, true)
    max_password_age              = optional(number, 90)
    password_reuse_prevention     = optional(number, 12)
    hard_expiry                   = optional(bool, false)
  })
  default = {}

  validation {
    condition     = var.account_password_policy.minimum_password_length >= 6 && var.account_password_policy.minimum_password_length <= 128
    error_message = "Minimum password length must be between 6 and 128 characters."
  }

  validation {
    condition     = var.account_password_policy.max_password_age >= 1 && var.account_password_policy.max_password_age <= 1095
    error_message = "Max password age must be between 1 and 1095 days."
  }

  validation {
    condition     = var.account_password_policy.password_reuse_prevention >= 1 && var.account_password_policy.password_reuse_prevention <= 24
    error_message = "Password reuse prevention must be between 1 and 24 passwords."
  }
}