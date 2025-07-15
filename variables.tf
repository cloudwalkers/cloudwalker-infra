# ============================================================================
# ROOT LEVEL VARIABLES
# ============================================================================
# Variables used at the root level for provider configuration and
# shared across multiple modules
# ============================================================================

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) used for default tagging"
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
  default     = "cloudwalker"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}