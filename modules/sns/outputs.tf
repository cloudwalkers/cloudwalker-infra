# ============================================================================
# AWS SNS MODULE OUTPUTS
# ============================================================================
# Output values for SNS topics, subscriptions, and attributes
# Used for integration with other modules and external references
# ============================================================================

# ============================================================================
# STANDARD TOPIC OUTPUTS
# ============================================================================

output "topic_arn" {
  description = "ARN of the SNS topic"
  value       = var.create_topic ? aws_sns_topic.this[0].arn : null
}

output "topic_id" {
  description = "ID of the SNS topic"
  value       = var.create_topic ? aws_sns_topic.this[0].id : null
}

output "topic_name" {
  description = "Name of the SNS topic"
  value       = var.create_topic ? aws_sns_topic.this[0].name : null
}

output "topic_display_name" {
  description = "Display name of the SNS topic"
  value       = var.create_topic ? aws_sns_topic.this[0].display_name : null
}

output "topic_owner" {
  description = "AWS account ID of the SNS topic owner"
  value       = var.create_topic ? aws_sns_topic.this[0].owner : null
}

# ============================================================================
# FIFO TOPIC OUTPUTS
# ============================================================================

output "fifo_topic_arn" {
  description = "ARN of the FIFO SNS topic"
  value       = var.create_fifo_topic ? aws_sns_topic.fifo[0].arn : null
}

output "fifo_topic_id" {
  description = "ID of the FIFO SNS topic"
  value       = var.create_fifo_topic ? aws_sns_topic.fifo[0].id : null
}

output "fifo_topic_name" {
  description = "Name of the FIFO SNS topic"
  value       = var.create_fifo_topic ? aws_sns_topic.fifo[0].name : null
}

# ============================================================================
# ENCRYPTED TOPIC OUTPUTS
# ============================================================================

output "encrypted_topic_arn" {
  description = "ARN of the encrypted SNS topic"
  value       = var.create_encrypted_topic ? aws_sns_topic.encrypted[0].arn : null
}

output "encrypted_topic_id" {
  description = "ID of the encrypted SNS topic"
  value       = var.create_encrypted_topic ? aws_sns_topic.encrypted[0].id : null
}

output "encrypted_topic_name" {
  description = "Name of the encrypted SNS topic"
  value       = var.create_encrypted_topic ? aws_sns_topic.encrypted[0].name : null
}

# ============================================================================
# SUBSCRIPTION OUTPUTS
# ============================================================================

output "email_subscription_arns" {
  description = "List of email subscription ARNs"
  value       = aws_sns_topic_subscription.email[*].arn
}

output "sms_subscription_arns" {
  description = "List of SMS subscription ARNs"
  value       = aws_sns_topic_subscription.sms[*].arn
}

output "sqs_subscription_arns" {
  description = "List of SQS subscription ARNs"
  value       = aws_sns_topic_subscription.sqs[*].arn
}

output "lambda_subscription_arns" {
  description = "List of Lambda subscription ARNs"
  value       = aws_sns_topic_subscription.lambda[*].arn
}

output "http_subscription_arns" {
  description = "List of HTTP/HTTPS subscription ARNs"
  value       = aws_sns_topic_subscription.http[*].arn
}

output "application_subscription_arns" {
  description = "List of application subscription ARNs"
  value       = aws_sns_topic_subscription.application[*].arn
}

output "fifo_sqs_subscription_arns" {
  description = "List of FIFO SQS subscription ARNs"
  value       = aws_sns_topic_subscription.fifo_sqs[*].arn
}

# ============================================================================
# SUBSCRIPTION COUNTS
# ============================================================================

output "subscription_counts" {
  description = "Count of subscriptions by type"
  value = {
    email       = length(var.email_subscriptions)
    sms         = length(var.sms_subscriptions)
    sqs         = length(var.sqs_subscriptions)
    lambda      = length(var.lambda_subscriptions)
    http        = length(var.http_subscriptions)
    application = length(var.application_subscriptions)
    fifo_sqs    = length(var.fifo_sqs_subscriptions)
    total       = (
      length(var.email_subscriptions) +
      length(var.sms_subscriptions) +
      length(var.sqs_subscriptions) +
      length(var.lambda_subscriptions) +
      length(var.http_subscriptions) +
      length(var.application_subscriptions) +
      length(var.fifo_sqs_subscriptions)
    )
  }
}

# ============================================================================
# TOPIC CONFIGURATION OUTPUTS
# ============================================================================

output "topic_configuration" {
  description = "Configuration details of the SNS topic"
  value = var.create_topic ? {
    arn                    = aws_sns_topic.this[0].arn
    name                   = aws_sns_topic.this[0].name
    display_name           = aws_sns_topic.this[0].display_name
    policy                 = aws_sns_topic.this[0].policy
    delivery_policy        = aws_sns_topic.this[0].delivery_policy
    kms_master_key_id      = aws_sns_topic.this[0].kms_master_key_id
    fifo_topic             = aws_sns_topic.this[0].fifo_topic
    content_based_deduplication = aws_sns_topic.this[0].content_based_deduplication
  } : null
}

output "fifo_topic_configuration" {
  description = "Configuration details of the FIFO SNS topic"
  value = var.create_fifo_topic ? {
    arn                         = aws_sns_topic.fifo[0].arn
    name                        = aws_sns_topic.fifo[0].name
    fifo_topic                  = aws_sns_topic.fifo[0].fifo_topic
    content_based_deduplication = aws_sns_topic.fifo[0].content_based_deduplication
    policy                      = aws_sns_topic.fifo[0].policy
    delivery_policy             = aws_sns_topic.fifo[0].delivery_policy
  } : null
}

# ============================================================================
# SUBSCRIPTION DETAILS
# ============================================================================

output "email_subscriptions_details" {
  description = "Details of email subscriptions"
  value = [
    for i, sub in aws_sns_topic_subscription.email : {
      arn                  = sub.arn
      endpoint             = sub.endpoint
      protocol             = sub.protocol
      filter_policy        = sub.filter_policy
      raw_message_delivery = sub.raw_message_delivery
      confirmation_was_authenticated = sub.confirmation_was_authenticated
      pending_confirmation = sub.pending_confirmation
    }
  ]
}

output "sqs_subscriptions_details" {
  description = "Details of SQS subscriptions"
  value = [
    for i, sub in aws_sns_topic_subscription.sqs : {
      arn                  = sub.arn
      endpoint             = sub.endpoint
      protocol             = sub.protocol
      filter_policy        = sub.filter_policy
      raw_message_delivery = sub.raw_message_delivery
      redrive_policy       = sub.redrive_policy
    }
  ]
}

output "lambda_subscriptions_details" {
  description = "Details of Lambda subscriptions"
  value = [
    for i, sub in aws_sns_topic_subscription.lambda : {
      arn           = sub.arn
      endpoint      = sub.endpoint
      protocol      = sub.protocol
      filter_policy = sub.filter_policy
    }
  ]
}

# ============================================================================
# INTEGRATION OUTPUTS
# ============================================================================

output "topic_policy" {
  description = "Topic policy JSON document"
  value       = var.create_topic ? aws_sns_topic.this[0].policy : null
  sensitive   = true
}

output "delivery_policy" {
  description = "Delivery policy JSON document"
  value       = var.create_topic ? aws_sns_topic.this[0].delivery_policy : null
}

output "data_protection_policy_arn" {
  description = "ARN of the data protection policy"
  value       = var.create_topic && var.data_protection_policy != null ? aws_sns_topic_data_protection_policy.this[0].arn : null
}

# ============================================================================
# TOPIC ATTRIBUTES FOR REFERENCE
# ============================================================================

output "topic_attributes" {
  description = "Complete topic attributes for reference"
  value = var.create_topic ? {
    arn                                      = aws_sns_topic.this[0].arn
    id                                       = aws_sns_topic.this[0].id
    name                                     = aws_sns_topic.this[0].name
    display_name                             = aws_sns_topic.this[0].display_name
    owner                                    = aws_sns_topic.this[0].owner
    policy                                   = aws_sns_topic.this[0].policy
    delivery_policy                          = aws_sns_topic.this[0].delivery_policy
    application_success_feedback_role_arn    = aws_sns_topic.this[0].application_success_feedback_role_arn
    application_success_feedback_sample_rate = aws_sns_topic.this[0].application_success_feedback_sample_rate
    application_failure_feedback_role_arn    = aws_sns_topic.this[0].application_failure_feedback_role_arn
    http_success_feedback_role_arn           = aws_sns_topic.this[0].http_success_feedback_role_arn
    http_success_feedback_sample_rate        = aws_sns_topic.this[0].http_success_feedback_sample_rate
    http_failure_feedback_role_arn           = aws_sns_topic.this[0].http_failure_feedback_role_arn
    lambda_success_feedback_role_arn         = aws_sns_topic.this[0].lambda_success_feedback_role_arn
    lambda_success_feedback_sample_rate      = aws_sns_topic.this[0].lambda_success_feedback_sample_rate
    lambda_failure_feedback_role_arn         = aws_sns_topic.this[0].lambda_failure_feedback_role_arn
    sqs_success_feedback_role_arn            = aws_sns_topic.this[0].sqs_success_feedback_role_arn
    sqs_success_feedback_sample_rate         = aws_sns_topic.this[0].sqs_success_feedback_sample_rate
    sqs_failure_feedback_role_arn            = aws_sns_topic.this[0].sqs_failure_feedback_role_arn
    kms_master_key_id                        = aws_sns_topic.this[0].kms_master_key_id
    fifo_topic                               = aws_sns_topic.this[0].fifo_topic
    content_based_deduplication              = aws_sns_topic.this[0].content_based_deduplication
  } : null
}