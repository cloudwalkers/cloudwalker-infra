# ============================================================================
# AWS SQS (Simple Queue Service) MODULE
# ============================================================================
# This module creates and manages AWS SQS queues for reliable message queuing
# and decoupling of distributed systems. SQS provides:
# - Reliable message delivery with at-least-once delivery guarantee
# - Scalable message queuing without infrastructure management
# - Dead letter queue support for failed message handling
# - Message encryption and access control
# - Integration with other AWS services
# ============================================================================

# ============================================================================
# STANDARD SQS QUEUE
# ============================================================================
# Primary message queue for standard message processing
# Provides reliable message delivery with configurable retention and visibility
# Supports message attributes, encryption, and access policies
resource "aws_sqs_queue" "main" {
  count = var.create_queue ? 1 : 0

  name                       = var.queue_name
  delay_seconds              = var.delay_seconds              # Time to delay message delivery (0-900 seconds)
  max_message_size           = var.max_message_size           # Maximum message size in bytes (1024-262144)
  message_retention_seconds  = var.message_retention_seconds  # How long messages are retained (60-1209600 seconds)
  receive_wait_time_seconds  = var.receive_wait_time_seconds  # Long polling wait time (0-20 seconds)
  visibility_timeout_seconds = var.visibility_timeout_seconds # Message visibility timeout (0-43200 seconds)

  # Enable server-side encryption if specified
  # Uses AWS managed keys (SSE-SQS) or customer managed keys (SSE-KMS)
  dynamic "kms_master_key_id" {
    for_each = var.kms_master_key_id != null ? [var.kms_master_key_id] : []
    content {
      kms_master_key_id = kms_master_key_id.value
    }
  }

  # Configure dead letter queue for failed message handling
  # Messages that exceed max_receive_count are moved to DLQ
  dynamic "redrive_policy" {
    for_each = var.create_dlq ? [1] : []
    content {
      redrive_policy = jsonencode({
        deadLetterTargetArn = aws_sqs_queue.dlq[0].arn
        maxReceiveCount     = var.max_receive_count
      })
    }
  }

  # Apply resource tags for organization and cost tracking
  tags = merge(
    var.tags,
    {
      Name        = var.queue_name
      Environment = var.environment
      Module      = "sqs"
    }
  )
}

# ============================================================================
# DEAD LETTER QUEUE (DLQ)
# ============================================================================
# Secondary queue for messages that fail processing multiple times
# Provides isolation for problematic messages and enables debugging
# Typically has longer retention period for analysis
resource "aws_sqs_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name                       = "${var.queue_name}-dlq"
  message_retention_seconds  = var.dlq_message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Apply consistent tagging with DLQ identifier
  tags = merge(
    var.tags,
    {
      Name        = "${var.queue_name}-dlq"
      Environment = var.environment
      Module      = "sqs"
      Type        = "dead-letter-queue"
    }
  )
}

# ============================================================================
# FIFO QUEUE (Optional)
# ============================================================================
# First-In-First-Out queue for ordered message processing
# Provides exactly-once processing and message ordering
# Required for applications that need strict message ordering
resource "aws_sqs_queue" "fifo" {
  count = var.create_fifo_queue ? 1 : 0

  name                        = "${var.queue_name}.fifo"
  fifo_queue                  = true
  content_based_deduplication = var.content_based_deduplication
  deduplication_scope         = var.deduplication_scope
  fifo_throughput_limit       = var.fifo_throughput_limit

  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  # Configure DLQ for FIFO queue if enabled
  dynamic "redrive_policy" {
    for_each = var.create_fifo_dlq ? [1] : []
    content {
      redrive_policy = jsonencode({
        deadLetterTargetArn = aws_sqs_queue.fifo_dlq[0].arn
        maxReceiveCount     = var.max_receive_count
      })
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.queue_name}.fifo"
      Environment = var.environment
      Module      = "sqs"
      Type        = "fifo-queue"
    }
  )
}

# ============================================================================
# FIFO DEAD LETTER QUEUE
# ============================================================================
# Dead letter queue for FIFO queue failed messages
# Maintains FIFO characteristics for failed message analysis
resource "aws_sqs_queue" "fifo_dlq" {
  count = var.create_fifo_dlq ? 1 : 0

  name                        = "${var.queue_name}-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = var.content_based_deduplication
  message_retention_seconds   = var.dlq_message_retention_seconds

  tags = merge(
    var.tags,
    {
      Name        = "${var.queue_name}-dlq.fifo"
      Environment = var.environment
      Module      = "sqs"
      Type        = "fifo-dead-letter-queue"
    }
  )
}

# ============================================================================
# QUEUE POLICY (Optional)
# ============================================================================
# IAM policy for queue access control
# Defines who can send, receive, and manage messages
# Supports cross-account access and service integration
resource "aws_sqs_queue_policy" "main" {
  count = var.queue_policy != null ? 1 : 0

  queue_url = aws_sqs_queue.main[0].id
  policy    = var.queue_policy
}

resource "aws_sqs_queue_policy" "fifo" {
  count = var.create_fifo_queue && var.fifo_queue_policy != null ? 1 : 0

  queue_url = aws_sqs_queue.fifo[0].id
  policy    = var.fifo_queue_policy
}