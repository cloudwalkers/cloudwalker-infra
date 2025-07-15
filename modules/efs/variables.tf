# ============================================================================
# AWS EFS MODULE VARIABLES
# ============================================================================
# Variable definitions for EFS file system configuration
# Supports comprehensive file system features and access control
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "name" {
  description = "Name of the EFS file system"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all EFS resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# FILE SYSTEM CREATION
# ============================================================================

variable "create_file_system" {
  description = "Whether to create the EFS file system"
  type        = bool
  default     = true
}

variable "creation_token" {
  description = "Unique creation token for the file system (auto-generated if not provided)"
  type        = string
  default     = null
}

# ============================================================================
# PERFORMANCE CONFIGURATION
# ============================================================================

variable "performance_mode" {
  description = "Performance mode for the file system (generalPurpose or maxIO)"
  type        = string
  default     = "generalPurpose"

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.performance_mode)
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }
}

variable "throughput_mode" {
  description = "Throughput mode for the file system (bursting or provisioned)"
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned"], var.throughput_mode)
    error_message = "Throughput mode must be either 'bursting' or 'provisioned'."
  }
}

variable "provisioned_throughput" {
  description = "Provisioned throughput in MiB/s (required if throughput_mode is provisioned)"
  type        = number
  default     = null

  validation {
    condition     = var.provisioned_throughput == null || (var.provisioned_throughput >= 1 && var.provisioned_throughput <= 1024)
    error_message = "Provisioned throughput must be between 1 and 1024 MiB/s."
  }
}

# ============================================================================
# ENCRYPTION CONFIGURATION
# ============================================================================

variable "encrypted" {
  description = "Enable encryption at rest for the file system"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (uses AWS managed key if not specified)"
  type        = string
  default     = null
}

# ============================================================================
# LIFECYCLE POLICY
# ============================================================================

variable "lifecycle_policy" {
  description = "Lifecycle policy for transitioning files to Infrequent Access storage class"
  type = object({
    transition_to_ia                    = optional(string)
    transition_to_primary_storage_class = optional(string)
  })
  default = null

  validation {
    condition = var.lifecycle_policy == null || (
      var.lifecycle_policy.transition_to_ia == null || contains([
        "AFTER_7_DAYS", "AFTER_14_DAYS", "AFTER_30_DAYS", "AFTER_60_DAYS", "AFTER_90_DAYS"
      ], var.lifecycle_policy.transition_to_ia)
    )
    error_message = "Invalid transition_to_ia value. Must be one of: AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS."
  }

  validation {
    condition = var.lifecycle_policy == null || (
      var.lifecycle_policy.transition_to_primary_storage_class == null || contains([
        "AFTER_1_ACCESS"
      ], var.lifecycle_policy.transition_to_primary_storage_class)
    )
    error_message = "Invalid transition_to_primary_storage_class value. Must be: AFTER_1_ACCESS."
  }
}

# ============================================================================
# NETWORKING CONFIGURATION
# ============================================================================

variable "vpc_id" {
  description = "VPC ID where the EFS file system will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for EFS mount targets (typically private subnets)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the EFS file system"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs allowed to access the EFS file system"
  type        = list(string)
  default     = []
}

# ============================================================================
# BACKUP CONFIGURATION
# ============================================================================

variable "backup_enabled" {
  description = "Enable automatic backups using AWS Backup"
  type        = bool
  default     = true
}

# ============================================================================
# ACCESS POINTS CONFIGURATION
# ============================================================================

variable "access_points" {
  description = "Map of access points to create for the file system"
  type = map(object({
    posix_user = optional(object({
      gid            = number
      uid            = number
      secondary_gids = optional(list(number))
    }))
    root_directory = optional(object({
      path = string
      creation_info = optional(object({
        owner_gid   = number
        owner_uid   = number
        permissions = string
      }))
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

# ============================================================================
# FILE SYSTEM POLICY
# ============================================================================

variable "file_system_policy" {
  description = "JSON policy document for the EFS file system"
  type        = string
  default     = null
}

variable "bypass_policy_lockout_safety_check" {
  description = "Bypass the policy lockout safety check"
  type        = bool
  default     = false
}

# ============================================================================
# REPLICATION CONFIGURATION
# ============================================================================

variable "replication_configuration" {
  description = "Replication configuration for cross-region backup"
  type = object({
    destination_region     = string
    availability_zone_name = optional(string)
    kms_key_id            = optional(string)
  })
  default = null
}