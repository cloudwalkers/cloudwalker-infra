module "iam" {
  source = "../../modules/iam"

  roles = var.roles

  tags = {
    Environment = "test"
    Purpose     = "terratest"
  }
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "roles" {
  description = "Map of roles to create"
  type        = any
  default     = {}
}

output "roles" {
  value = module.iam.roles
}

output "role_arns" {
  value = module.iam.role_arns
}

output "instance_profiles" {
  value = module.iam.instance_profiles
}