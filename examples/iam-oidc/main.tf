module "iam" {
  source = "../../modules/iam"

  oidc_providers = var.oidc_providers

  tags = {
    Environment = "test"
    Purpose     = "terratest"
  }
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "oidc_providers" {
  description = "Map of OIDC providers to create"
  type        = any
  default     = {}
}

output "oidc_providers" {
  value = module.iam.oidc_providers
}