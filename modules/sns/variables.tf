# ============================================================================
# AWS SNS MODULE VARIABLES
# ============================================================================
# Variable definitions for SNS topic and subscription configuration
# Supports comprehensive messaging features and delivery options
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all SNS resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# TOPIC CREATION FLAGS
# ============================================================================

variable "create_topic" {
  description = "Whether to create the standard SNS topic"
  type        = bool
  default     = true
}

variable "create_fifo_topic" {
  description = "Whether to create a FIFO SNS topic"
  type        = bool
  default     = false
}

variable "create_encrypted_topic" {
  description = "Whether to create an encrypted SNS topic"
  type        = bool
  default     = false
}

# ============================================================================
# TOPIC CONFIGURATION
# ============================================================================

variable "display_name" {
  description = "Display name for the SNS topic"
  type        = string
  default     = null
}

variable "topic_policy" {
  description = "JSON policy document for the SNS topic access control"
  type        = string
  default     = null
}

variable "fifo_topic_policy" {
  description = "JSON policy document for the FIFO SNS topic access control"
  type        = string
  default     = null
}

variable "delivery_policy" {
  description = "JSON delivery policy for message delivery retry behavior"
  type        = string
  default     = null
}

# ============================================================================
# FIFO CONFIGURATION
# ============================================================================

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO topic"
  type        = bool
  default     = false
}

# ============================================================================
# ENCRYPTION CONFIGURATION
# ============================================================================

variable "kms_master_key_id" {
  description = "KMS key ID for server-side encryption"
  type        = string
  default     = null
}

# ============================================================================
# DELIVERY STATUS LOGGING
# ============================================================================

variable "application_success_feedback_role_arn" {
  description = "IAM role ARN for application platform success feedback"
  type        = string
  default     = null
}

variable "application_success_feedback_sample_rate" {
  description = "Sample rate for application platform success feedback (0-100)"
  type        = number
  default     = null

  validation {
    condition     = var.application_success_feedback_sample_rate == null || (var.application_success_feedback_sample_rate >= 0 && var.application_success_feedback_sample_rate <= 100)
    error_message = "Application success feedback sample rate must be between 0 and 100."
  }
}

variable "application_failure_feedback_role_arn" {
  description = "IAM role ARN for application platform failure feedback"
  type        = string
  default     = null
}

variable "http_success_feedback_role_arn" {
  description = "IAM role ARN for HTTP success feedback"
  type        = string
  default     = null
}

variable "http_success_feedback_sample_rate" {
  description = "Sample rate for HTTP success feedback (0-100)"
  type        = number
  default     = null

  validation {
    condition     = var.http_success_feedback_sample_rate == null || (var.http_success_feedback_sample_rate >= 0 && var.http_success_feedback_sample_rate <= 100)
    error_message = "HTTP success feedback sample rate must be between 0 and 100."
  }
}

variable "http_failure_feedback_role_arn" {
  description = "IAM role ARN for HTTP failure feedback"
  type        = string
  default     = null
}

variable "lambda_success_feedback_role_arn" {
  description = "IAM role ARN for Lambda success feedback"
  type        = string
  default     = null
}

variable "lambda_success_feedback_sample_rate" {
  description = "Sample rate for Lambda success feedback (0-100)"
  type        = number
  default     = null

  validation {
    condition     = var.lambda_success_feedback_sample_rate == null || (var.lambda_success_feedback_sample_rate >= 0 && var.lambda_success_feedback_sample_rate <= 100)
    error_message = "Lambda success feedback sample rate must be between 0 and 100."
  }
}

variable "lambda_failure_feedback_role_arn" {
  description = "IAM role ARN for Lambda failure feedback"
  type        = string
  default     = null
}

variable "sqs_success_feedback_role_arn" {
  description = "IAM role ARN for SQS success feedback"
  type        = string
  default     = null
}

variable "sqs_success_feedback_sample_rate" {
  description = "Sample rate for SQS success feedback (0-100)"
  type        = number
  default     = null

  validation {
    condition     = var.sqs_success_feedback_sample_rate == null || (var.sqs_success_feedback_sample_rate >= 0 && var.sqs_success_feedback_sample_rate <= 100)
    error_message = "SQS success feedback sample rate must be between 0 and 100."
  }
}

variable "sqs_failure_feedback_role_arn" {
  description = "IAM role ARN for SQS failure feedback"
  type        = string
  default     = null
}

# ============================================================================
# EMAIL SUBSCRIPTIONS
# ============================================================================

variable "email_subscriptions" {
  description = "List of email subscriptions"
  type = list(object({
    email                = string
    filter_policy        = optional(map(any))
    delivery_policy      = optional(map(any))
    raw_message_delivery = optional(bool, false)
  }))
  default = []

  validation {
    condition = alltrue([
      for sub in var.email_subscriptions : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", sub.email))
    ])
    error_message = "All email addresses must be valid."
  }
}

# ============================================================================
# SMS SUBSCRIPTIONS
# ============================================================================

variable "sms_subscriptions" {
  description = "List of SMS subscriptions"
  type = list(object({
    phone_number     = string
    filter_policy    = optional(map(any))
    delivery_policy  = optional(map(any))
  }))
  default = []

  validation {
    condition = alltrue([
      for sub in var.sms_subscriptions : can(regex("^\\+[1-9]\\d{1,14}$", sub.phone_number))
    ])
    error_message = "All phone numbers must be in E.164 format (e.g., +1234567890)."
  }
}

# ============================================================================
# SQS SUBSCRIPTIONS
# ============================================================================

variable "sqs_subscriptions" {
  description = "List of SQS queue subscriptions"
  type = list(object({
    queue_arn            = string
    filter_policy        = optional(map(any))
    delivery_policy      = optional(map(any))
    raw_message_delivery = optional(bool, false)
    redrive_policy       = optional(map(any))
  }))
  default = []
}

# ============================================================================
# LAMBDA SUBSCRIPTIONS
# ============================================================================

variable "lambda_subscriptions" {
  description = "List of Lambda function subscriptions"
  type = list(object({
    function_arn     = string
    filter_policy    = optional(map(any))
    delivery_policy  = optional(map(any))
  }))
  default = []
}

# ============================================================================
# HTTP/HTTPS SUBSCRIPTIONS
# ============================================================================

variable "http_subscriptions" {
  description = "List of HTTP/HTTPS webhook subscriptions"
  type = list(object({
    protocol                        = string
    endpoint                        = string
    filter_policy                   = optional(map(any))
    delivery_policy                 = optional(map(any))
    raw_message_delivery            = optional(bool, false)
    confirmation_timeout_in_minutes = optional(number, 1)
  }))
  default = []

  validation {
    condition = alltrue([
      for sub in var.http_subscriptions : contains(["http", "https"], sub.protocol)
    ])
    error_message = "HTTP subscription protocol must be either 'http' or 'https'."
  }

  validation {
    condition = alltrue([
      for sub in var.http_subscriptions : can(regex("^https?://", sub.endpoint))
    ])
    error_message = "HTTP subscription endpoints must be valid URLs."
  }
}

# ============================================================================
# APPLICATION SUBSCRIPTIONS
# ============================================================================

variable "application_subscriptions" {
  description = "List of mobile application subscriptions"
  type = list(object({
    endpoint_arn     = string
    filter_policy    = optional(map(any))
    delivery_policy  = optional(map(any))
  }))
  default = []
}

# ============================================================================
# FIFO SQS SUBSCRIPTIONS
# ============================================================================

variable "fifo_sqs_subscriptions" {
  description = "List of SQS FIFO queue subscriptions for FIFO topic"
  type = list(object({
    queue_arn            = string
    filter_policy        = optional(map(any))
    raw_message_delivery = optional(bool, false)
  }))
  default = []
}

# ============================================================================
# DATA PROTECTION
# ============================================================================

variable "data_protection_policy" {
  description = "JSON data protection policy for sensitive data handling"
  type        = string
  default     = null
}