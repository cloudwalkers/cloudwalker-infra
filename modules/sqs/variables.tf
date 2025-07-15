# ============================================================================
# AWS SQS MODULE VARIABLES
# ============================================================================
# Variable definitions for SQS queue configuration
# Supports standard queues, FIFO queues, dead letter queues, and policies
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "queue_name" {
  description = "Name of the SQS queue. For FIFO queues, .fifo will be appended automatically"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all SQS resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# QUEUE CREATION FLAGS
# ============================================================================

variable "create_queue" {
  description = "Whether to create the standard SQS queue"
  type        = bool
  default     = true
}

variable "create_dlq" {
  description = "Whether to create a dead letter queue for the standard queue"
  type        = bool
  default     = false
}

variable "create_fifo_queue" {
  description = "Whether to create a FIFO SQS queue"
  type        = bool
  default     = false
}

variable "create_fifo_dlq" {
  description = "Whether to create a dead letter queue for the FIFO queue"
  type        = bool
  default     = false
}

# ============================================================================
# STANDARD QUEUE CONFIGURATION
# ============================================================================

variable "delay_seconds" {
  description = "Time in seconds that the delivery of messages is delayed (0-900)"
  type        = number
  default     = 0

  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900
    error_message = "Delay seconds must be between 0 and 900."
  }
}

variable "max_message_size" {
  description = "Maximum message size in bytes (1024-262144)"
  type        = number
  default     = 262144

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "Max message size must be between 1024 and 262144 bytes."
  }
}

variable "message_retention_seconds" {
  description = "Number of seconds SQS retains messages (60-1209600, default 14 days)"
  type        = number
  default     = 1209600

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "Message retention must be between 60 and 1209600 seconds."
  }
}

variable "receive_wait_time_seconds" {
  description = "Time for which a ReceiveMessage call waits for a message (0-20, enables long polling if > 0)"
  type        = number
  default     = 0

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "Receive wait time must be between 0 and 20 seconds."
  }
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for messages in seconds (0-43200)"
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "Visibility timeout must be between 0 and 43200 seconds."
  }
}

# ============================================================================
# DEAD LETTER QUEUE CONFIGURATION
# ============================================================================

variable "max_receive_count" {
  description = "Maximum number of times a message can be received before being moved to DLQ"
  type        = number
  default     = 3

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "Max receive count must be between 1 and 1000."
  }
}

variable "dlq_message_retention_seconds" {
  description = "Message retention period for dead letter queue in seconds (60-1209600)"
  type        = number
  default     = 1209600

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "DLQ message retention must be between 60 and 1209600 seconds."
  }
}

# ============================================================================
# FIFO QUEUE CONFIGURATION
# ============================================================================

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO queue"
  type        = bool
  default     = false
}

variable "deduplication_scope" {
  description = "Specifies whether message deduplication occurs at message group or queue level (messageGroup or queue)"
  type        = string
  default     = "queue"

  validation {
    condition     = contains(["messageGroup", "queue"], var.deduplication_scope)
    error_message = "Deduplication scope must be either 'messageGroup' or 'queue'."
  }
}

variable "fifo_throughput_limit" {
  description = "Specifies whether FIFO queue throughput quota applies to entire queue or per message group (perQueue or perMessageGroupId)"
  type        = string
  default     = "perQueue"

  validation {
    condition     = contains(["perQueue", "perMessageGroupId"], var.fifo_throughput_limit)
    error_message = "FIFO throughput limit must be either 'perQueue' or 'perMessageGroupId'."
  }
}

# ============================================================================
# ENCRYPTION CONFIGURATION
# ============================================================================

variable "kms_master_key_id" {
  description = "ID of AWS KMS key for server-side encryption. If null, uses AWS managed key"
  type        = string
  default     = null
}

# ============================================================================
# ACCESS POLICY CONFIGURATION
# ============================================================================

variable "queue_policy" {
  description = "JSON policy document for the standard queue access control"
  type        = string
  default     = null
}

variable "fifo_queue_policy" {
  description = "JSON policy document for the FIFO queue access control"
  type        = string
  default     = null
}