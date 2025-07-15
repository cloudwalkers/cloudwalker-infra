# ============================================================================
# AWS S3 MODULE VARIABLES
# ============================================================================
# Variable definitions for S3 bucket configuration
# Supports comprehensive bucket features and security controls
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "S3 bucket name must be 3-63 characters, lowercase, and contain only letters, numbers, dots, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all S3 resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# BUCKET CREATION AND MANAGEMENT
# ============================================================================

variable "create_bucket" {
  description = "Whether to create the S3 bucket"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow deletion of non-empty bucket (use with caution in production)"
  type        = bool
  default     = false
}

# ============================================================================
# VERSIONING CONFIGURATION
# ============================================================================

variable "versioning_enabled" {
  description = "Enable S3 bucket versioning for data protection"
  type        = bool
  default     = true
}

# ============================================================================
# ENCRYPTION CONFIGURATION
# ============================================================================

variable "encryption_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be either 'AES256' or 'aws:kms'."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for server-side encryption (required if encryption_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Enable S3 bucket key for KMS encryption cost optimization"
  type        = bool
  default     = true
}

# ============================================================================
# PUBLIC ACCESS BLOCK CONFIGURATION
# ============================================================================

variable "block_public_acls" {
  description = "Block public ACLs on the bucket and objects"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Block public bucket policies"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs on the bucket and objects"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restrict public bucket policies"
  type        = bool
  default     = true
}

# ============================================================================
# LIFECYCLE CONFIGURATION
# ============================================================================

variable "lifecycle_rules" {
  description = "List of lifecycle rules for automated data management"
  type = list(object({
    id     = string
    status = string
    filter = optional(object({
      prefix = optional(string)
      tags   = optional(map(string))
    }))
    expiration = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))
    transitions = optional(list(object({
      days          = optional(number)
      date          = optional(string)
      storage_class = string
    })), [])
    noncurrent_version_expiration = optional(object({
      days = number
    }))
    noncurrent_version_transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }))
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules : contains(["Enabled", "Disabled"], rule.status)
    ])
    error_message = "Lifecycle rule status must be either 'Enabled' or 'Disabled'."
  }

  validation {
    condition = alltrue([
      for rule in var.lifecycle_rules : alltrue([
        for transition in rule.transitions : contains([
          "STANDARD_IA", "ONEZONE_IA", "REDUCED_REDUNDANCY", 
          "GLACIER", "DEEP_ARCHIVE", "INTELLIGENT_TIERING"
        ], transition.storage_class)
      ])
    ])
    error_message = "Invalid storage class in lifecycle transitions."
  }
}

# ============================================================================
# NOTIFICATION CONFIGURATION
# ============================================================================

variable "lambda_notifications" {
  description = "List of Lambda function notifications"
  type = list(object({
    lambda_function_arn = string
    events              = list(string)
    filter_prefix       = optional(string)
    filter_suffix       = optional(string)
  }))
  default = []
}

variable "sns_notifications" {
  description = "List of SNS topic notifications"
  type = list(object({
    topic_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = []
}

variable "sqs_notifications" {
  description = "List of SQS queue notifications"
  type = list(object({
    queue_arn     = string
    events        = list(string)
    filter_prefix = optional(string)
    filter_suffix = optional(string)
  }))
  default = []
}

# ============================================================================
# ACCESS POLICY CONFIGURATION
# ============================================================================

variable "bucket_policy" {
  description = "JSON policy document for bucket access control"
  type        = string
  default     = null
}

# ============================================================================
# CORS CONFIGURATION
# ============================================================================

variable "cors_rules" {
  description = "List of CORS rules for cross-origin access"
  type = list(object({
    allowed_headers = optional(list(string))
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default = []

  validation {
    condition = alltrue([
      for rule in var.cors_rules : alltrue([
        for method in rule.allowed_methods : contains([
          "GET", "PUT", "POST", "DELETE", "HEAD"
        ], method)
      ])
    ])
    error_message = "CORS allowed methods must be valid HTTP methods."
  }
}

# ============================================================================
# WEBSITE CONFIGURATION
# ============================================================================

variable "website_configuration" {
  description = "Static website hosting configuration"
  type = object({
    index_document = optional(string)
    error_document = optional(string)
    redirect_all_requests_to = optional(object({
      host_name = string
      protocol  = optional(string)
    }))
  })
  default = null
}

# ============================================================================
# LOGGING CONFIGURATION
# ============================================================================

variable "logging_configuration" {
  description = "Access logging configuration for audit and compliance"
  type = object({
    target_bucket = string
    target_prefix = optional(string)
  })
  default = null
}