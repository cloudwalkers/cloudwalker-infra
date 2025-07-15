# ============================================================================
# AWS SQS MODULE USAGE EXAMPLES
# ============================================================================
# Comprehensive examples showing different SQS queue configurations
# These examples demonstrate various use cases and best practices
# ============================================================================

# ============================================================================
# EXAMPLE 1: BASIC STANDARD QUEUE
# ============================================================================
# Simple SQS queue for basic message processing
# Suitable for most standard messaging scenarios

module "basic_queue" {
  source = "./modules/sqs"

  queue_name  = "my-basic-queue"
  environment = "dev"

  # Basic configuration with sensible defaults
  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600 # 14 days

  tags = {
    Project = "MyApplication"
    Owner   = "DevTeam"
  }
}

# ============================================================================
# EXAMPLE 2: QUEUE WITH DEAD LETTER QUEUE
# ============================================================================
# Standard queue with DLQ for handling failed messages
# Recommended for production workloads requiring reliability

module "queue_with_dlq" {
  source = "./modules/sqs"

  queue_name  = "processing-queue"
  environment = "prod"

  # Enable dead letter queue
  create_dlq        = true
  max_receive_count = 3

  # Extended retention for DLQ analysis
  dlq_message_retention_seconds = 1209600 # 14 days

  # Long polling for efficiency
  receive_wait_time_seconds = 20

  tags = {
    Project     = "OrderProcessing"
    Environment = "production"
    CriticalApp = "true"
  }
}

# ============================================================================
# EXAMPLE 3: FIFO QUEUE FOR ORDERED PROCESSING
# ============================================================================
# FIFO queue for applications requiring message ordering
# Ideal for financial transactions, inventory updates, etc.

module "fifo_queue" {
  source = "./modules/sqs"

  queue_name  = "order-processing"
  environment = "prod"

  # Create FIFO queue instead of standard
  create_queue      = false
  create_fifo_queue = true

  # FIFO-specific configuration
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"

  # Standard queue settings
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600 # 4 days

  tags = {
    Project = "ECommerce"
    Type    = "OrderProcessing"
    FIFO    = "true"
  }
}

# ============================================================================
# EXAMPLE 4: FIFO QUEUE WITH DEAD LETTER QUEUE
# ============================================================================
# Complete FIFO setup with error handling
# Production-ready configuration for critical ordered processing

module "fifo_queue_with_dlq" {
  source = "./modules/sqs"

  queue_name  = "critical-orders"
  environment = "prod"

  # Create FIFO queue with DLQ
  create_queue      = false
  create_fifo_queue = true
  create_fifo_dlq   = true

  # Error handling configuration
  max_receive_count = 5

  # FIFO configuration
  content_based_deduplication = true
  deduplication_scope         = "queue"
  fifo_throughput_limit       = "perQueue"

  # Timing configuration
  visibility_timeout_seconds    = 120
  message_retention_seconds     = 1209600 # 14 days
  dlq_message_retention_seconds = 1209600 # 14 days for analysis

  tags = {
    Project      = "PaymentProcessing"
    Environment  = "production"
    Compliance   = "PCI-DSS"
    OrderedQueue = "true"
  }
}

# ============================================================================
# EXAMPLE 5: ENCRYPTED QUEUE WITH CUSTOM POLICY
# ============================================================================
# Secure queue with KMS encryption and custom access policy
# Suitable for sensitive data processing

module "encrypted_queue" {
  source = "./modules/sqs"

  queue_name  = "secure-messages"
  environment = "prod"

  # Enable DLQ for reliability
  create_dlq        = true
  max_receive_count = 3

  # Security configuration
  kms_master_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Custom access policy (example)
  queue_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSpecificRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/MessageProcessorRole"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Project     = "SecureProcessing"
    Environment = "production"
    Encrypted   = "true"
    Compliance  = "SOC2"
  }
}

# ============================================================================
# EXAMPLE 6: HIGH-THROUGHPUT PROCESSING QUEUE
# ============================================================================
# Optimized for high-volume message processing
# Configuration for maximum throughput scenarios

module "high_throughput_queue" {
  source = "./modules/sqs"

  queue_name  = "bulk-processing"
  environment = "prod"

  # Optimized for throughput
  receive_wait_time_seconds  = 20  # Enable long polling
  visibility_timeout_seconds = 300 # 5 minutes for processing
  max_message_size          = 262144 # Maximum size

  # Shorter retention for high volume
  message_retention_seconds = 345600 # 4 days

  # DLQ for failed messages
  create_dlq        = true
  max_receive_count = 5

  tags = {
    Project    = "DataPipeline"
    UseCase    = "BulkProcessing"
    Throughput = "high"
  }
}

# ============================================================================
# EXAMPLE 7: MICROSERVICES COMMUNICATION
# ============================================================================
# Queue setup for microservices event-driven architecture
# Multiple queues for different service interactions

module "user_events_queue" {
  source = "./modules/sqs"

  queue_name  = "user-events"
  environment = "prod"

  # Event processing configuration
  delay_seconds             = 0
  visibility_timeout_seconds = 30
  receive_wait_time_seconds  = 10

  # Reliability features
  create_dlq        = true
  max_receive_count = 3

  tags = {
    Service     = "UserService"
    EventType   = "UserEvents"
    Architecture = "Microservices"
  }
}

module "notification_queue" {
  source = "./modules/sqs"

  queue_name  = "notifications"
  environment = "prod"

  # Notification-specific settings
  visibility_timeout_seconds = 60  # Time to send notification
  receive_wait_time_seconds  = 20  # Long polling

  # DLQ for failed notifications
  create_dlq                    = true
  max_receive_count             = 5
  dlq_message_retention_seconds = 1209600 # Keep failed notifications longer

  tags = {
    Service = "NotificationService"
    Type    = "EmailSMS"
  }
}