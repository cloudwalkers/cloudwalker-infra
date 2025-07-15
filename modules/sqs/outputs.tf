# ============================================================================
# AWS SQS MODULE OUTPUTS
# ============================================================================
# Output values for SQS queues, ARNs, URLs, and attributes
# Used for integration with other modules and external references
# ============================================================================

# ============================================================================
# STANDARD QUEUE OUTPUTS
# ============================================================================

output "queue_id" {
  description = "URL of the standard SQS queue"
  value       = var.create_queue ? aws_sqs_queue.main[0].id : null
}

output "queue_arn" {
  description = "ARN of the standard SQS queue"
  value       = var.create_queue ? aws_sqs_queue.main[0].arn : null
}

output "queue_url" {
  description = "URL of the standard SQS queue (same as queue_id)"
  value       = var.create_queue ? aws_sqs_queue.main[0].url : null
}

output "queue_name" {
  description = "Name of the standard SQS queue"
  value       = var.create_queue ? aws_sqs_queue.main[0].name : null
}

# ============================================================================
# DEAD LETTER QUEUE OUTPUTS
# ============================================================================

output "dlq_id" {
  description = "URL of the dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].id : null
}

output "dlq_arn" {
  description = "ARN of the dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].arn : null
}

output "dlq_url" {
  description = "URL of the dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].url : null
}

output "dlq_name" {
  description = "Name of the dead letter queue"
  value       = var.create_dlq ? aws_sqs_queue.dlq[0].name : null
}

# ============================================================================
# FIFO QUEUE OUTPUTS
# ============================================================================

output "fifo_queue_id" {
  description = "URL of the FIFO SQS queue"
  value       = var.create_fifo_queue ? aws_sqs_queue.fifo[0].id : null
}

output "fifo_queue_arn" {
  description = "ARN of the FIFO SQS queue"
  value       = var.create_fifo_queue ? aws_sqs_queue.fifo[0].arn : null
}

output "fifo_queue_url" {
  description = "URL of the FIFO SQS queue"
  value       = var.create_fifo_queue ? aws_sqs_queue.fifo[0].url : null
}

output "fifo_queue_name" {
  description = "Name of the FIFO SQS queue"
  value       = var.create_fifo_queue ? aws_sqs_queue.fifo[0].name : null
}

# ============================================================================
# FIFO DEAD LETTER QUEUE OUTPUTS
# ============================================================================

output "fifo_dlq_id" {
  description = "URL of the FIFO dead letter queue"
  value       = var.create_fifo_dlq ? aws_sqs_queue.fifo_dlq[0].id : null
}

output "fifo_dlq_arn" {
  description = "ARN of the FIFO dead letter queue"
  value       = var.create_fifo_dlq ? aws_sqs_queue.fifo_dlq[0].arn : null
}

output "fifo_dlq_url" {
  description = "URL of the FIFO dead letter queue"
  value       = var.create_fifo_dlq ? aws_sqs_queue.fifo_dlq[0].url : null
}

output "fifo_dlq_name" {
  description = "Name of the FIFO dead letter queue"
  value       = var.create_fifo_dlq ? aws_sqs_queue.fifo_dlq[0].name : null
}

# ============================================================================
# QUEUE ATTRIBUTES
# ============================================================================

output "queue_attributes" {
  description = "All attributes of the standard SQS queue"
  value = var.create_queue ? {
    delay_seconds              = aws_sqs_queue.main[0].delay_seconds
    max_message_size           = aws_sqs_queue.main[0].max_message_size
    message_retention_seconds  = aws_sqs_queue.main[0].message_retention_seconds
    receive_wait_time_seconds  = aws_sqs_queue.main[0].receive_wait_time_seconds
    visibility_timeout_seconds = aws_sqs_queue.main[0].visibility_timeout_seconds
  } : null
}

output "fifo_queue_attributes" {
  description = "All attributes of the FIFO SQS queue"
  value = var.create_fifo_queue ? {
    delay_seconds                   = aws_sqs_queue.fifo[0].delay_seconds
    max_message_size                = aws_sqs_queue.fifo[0].max_message_size
    message_retention_seconds       = aws_sqs_queue.fifo[0].message_retention_seconds
    receive_wait_time_seconds       = aws_sqs_queue.fifo[0].receive_wait_time_seconds
    visibility_timeout_seconds      = aws_sqs_queue.fifo[0].visibility_timeout_seconds
    content_based_deduplication     = aws_sqs_queue.fifo[0].content_based_deduplication
    deduplication_scope             = aws_sqs_queue.fifo[0].deduplication_scope
    fifo_throughput_limit           = aws_sqs_queue.fifo[0].fifo_throughput_limit
  } : null
}