module "iam" {
  source = "../../modules/iam"

  users  = var.users
  groups = var.groups

  tags = {
    Environment = "test"
    Purpose     = "terratest"
  }
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "users" {
  description = "Map of users to create"
  type        = any
  default     = {}
}

variable "groups" {
  description = "Map of groups to create"
  type        = any
  default     = {}
}

output "users" {
  value = module.iam.users
}

output "groups" {
  value = module.iam.groups
}

output "user_arns" {
  value = module.iam.user_arns
}

output "group_arns" {
  value = module.iam.group_arns
}