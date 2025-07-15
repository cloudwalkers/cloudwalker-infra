module "iam" {
  source = "../../modules/iam"

  policies = var.policies
  users    = var.users

  tags = {
    Environment = "test"
    Purpose     = "terratest"
  }
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "policies" {
  description = "Map of policies to create"
  type        = any
  default     = {}
}

variable "users" {
  description = "Map of users to create"
  type        = any
  default     = {}
}

output "policies" {
  value = module.iam.policies
}

output "policy_arns" {
  value = module.iam.policy_arns
}

output "users" {
  value = module.iam.users
}