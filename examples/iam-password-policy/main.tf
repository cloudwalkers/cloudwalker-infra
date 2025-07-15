module "iam" {
  source = "../../modules/iam"

  account_password_policy = var.account_password_policy

  tags = {
    Environment = "test"
    Purpose     = "terratest"
  }
}

variable "account_password_policy" {
  description = "Account password policy configuration"
  type        = any
  default     = {}
}