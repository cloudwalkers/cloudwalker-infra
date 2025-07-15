# ============================================================================
# AWS SNS (Simple Notification Service) MODULE
# ============================================================================
# This module creates and manages AWS SNS topics and subscriptions for
# reliable message delivery and pub/sub messaging patterns. SNS provides:
# - Scalable pub/sub messaging with multiple delivery protocols
# - Message filtering and fanout capabilities
# - Integration with AWS services and external endpoints
# - Dead letter queue support for failed deliveries
# - Message encryption and access control
# - FIFO topics for ordered message delivery
# ============================================================================

# ============================================================================
# STANDARD SNS TOPIC
# ============================================================================
# Primary SNS topic for pub/sub messaging
# Provides reliable message delivery to multiple subscribers
# Supports message filtering, encryption, and access policies
resource "aws_sns_topic" "this" {
  count = var.create_topic ? 1 : 0

  name                        = var.topic_name
  display_name               = var.display_name
  policy                     = var.topic_policy
  delivery_policy            = var.delivery_policy
  application_success_feedback_role_arn    = var.application_success_feedback_role_arn
  application_success_feedback_sample_rate = var.application_success_feedback_sample_rate
  application_failure_feedback_role_arn    = var.application_failure_feedback_role_arn
  http_success_feedback_role_arn           = var.http_success_feedback_role_arn
  http_success_feedback_sample_rate        = var.http_success_feedback_sample_rate
  http_failure_feedback_role_arn           = var.http_failure_feedback_role_arn
  lambda_success_feedback_role_arn         = var.lambda_success_feedback_role_arn
  lambda_success_feedback_sample_rate      = var.lambda_success_feedback_sample_rate
  lambda_failure_feedback_role_arn         = var.lambda_failure_feedback_role_arn
  sqs_success_feedback_role_arn            = var.sqs_success_feedback_role_arn
  sqs_success_feedback_sample_rate         = var.sqs_success_feedback_sample_rate
  sqs_failure_feedback_role_arn            = var.sqs_failure_feedback_role_arn

  tags = merge(
    var.tags,
    {
      Name        = var.topic_name
      Environment = var.environment
      Module      = "sns"
    }
  )
}

# ============================================================================
# FIFO SNS TOPIC
# ============================================================================
# FIFO topic for ordered message delivery
# Provides exactly-once delivery and message ordering
# Required for applications needing strict message ordering
resource "aws_sns_topic" "fifo" {
  count = var.create_fifo_topic ? 1 : 0

  name                          = "${var.topic_name}.fifo"
  fifo_topic                    = true
  content_based_deduplication   = var.content_based_deduplication
  policy                        = var.fifo_topic_policy
  delivery_policy               = var.delivery_policy

  tags = merge(
    var.tags,
    {
      Name        = "${var.topic_name}.fifo"
      Environment = var.environment
      Module      = "sns"
      Type        = "fifo"
    }
  )
}

# ============================================================================
# SNS TOPIC ENCRYPTION
# ============================================================================
# Server-side encryption for message security
# Uses AWS managed keys or customer managed KMS keys
# Ensures message confidentiality in transit and at rest
resource "aws_sns_topic" "encrypted" {
  count = var.create_encrypted_topic ? 1 : 0

  name            = "${var.topic_name}-encrypted"
  kms_master_key_id = var.kms_master_key_id
  policy          = var.topic_policy
  delivery_policy = var.delivery_policy

  tags = merge(
    var.tags,
    {
      Name        = "${var.topic_name}-encrypted"
      Environment = var.environment
      Module      = "sns"
      Encrypted   = "true"
    }
  )
}

# ============================================================================
# EMAIL SUBSCRIPTIONS
# ============================================================================
# Email subscriptions for human notification workflows
# Supports both individual emails and mailing lists
# Requires manual confirmation for security
resource "aws_sns_topic_subscription" "email" {
  count = var.create_topic && length(var.email_subscriptions) > 0 ? length(var.email_subscriptions) : 0

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = "email"
  endpoint  = var.email_subscriptions[count.index].email

  # Message filtering based on attributes
  filter_policy = var.email_subscriptions[count.index].filter_policy != null ? jsonencode(var.email_subscriptions[count.index].filter_policy) : null

  # Delivery policy for retry behavior
  delivery_policy = var.email_subscriptions[count.index].delivery_policy != null ? jsonencode(var.email_subscriptions[count.index].delivery_policy) : null

  # Raw message delivery
  raw_message_delivery = var.email_subscriptions[count.index].raw_message_delivery
}

# ============================================================================
# SMS SUBSCRIPTIONS
# ============================================================================
# SMS subscriptions for mobile notifications
# Supports international phone numbers
# Ideal for critical alerts and notifications
resource "aws_sns_topic_subscription" "sms" {
  count = var.create_topic && length(var.sms_subscriptions) > 0 ? length(var.sms_subscriptions) : 0

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = "sms"
  endpoint  = var.sms_subscriptions[count.index].phone_number

  filter_policy   = var.sms_subscriptions[count.index].filter_policy != null ? jsonencode(var.sms_subscriptions[count.index].filter_policy) : null
  delivery_policy = var.sms_subscriptions[count.index].delivery_policy != null ? jsonencode(var.sms_subscriptions[count.index].delivery_policy) : null
}

# ============================================================================
# SQS SUBSCRIPTIONS
# ============================================================================
# SQS queue subscriptions for reliable message processing
# Enables decoupling between publishers and consumers
# Supports dead letter queues for failed message handling
resource "aws_sns_topic_subscription" "sqs" {
  count = var.create_topic && length(var.sqs_subscriptions) > 0 ? length(var.sqs_subscriptions) : 0

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = "sqs"
  endpoint  = var.sqs_subscriptions[count.index].queue_arn

  filter_policy       = var.sqs_subscriptions[count.index].filter_policy != null ? jsonencode(var.sqs_subscriptions[count.index].filter_policy) : null
  delivery_policy     = var.sqs_subscriptions[count.index].delivery_policy != null ? jsonencode(var.sqs_subscriptions[count.index].delivery_policy) : null
  raw_message_delivery = var.sqs_subscriptions[count.index].raw_message_delivery

  # Redrive policy for dead letter queue support
  redrive_policy = var.sqs_subscriptions[count.index].redrive_policy != null ? jsonencode(var.sqs_subscriptions[count.index].redrive_policy) : null
}

# ============================================================================
# LAMBDA SUBSCRIPTIONS
# ============================================================================
# Lambda function subscriptions for serverless processing
# Enables event-driven architectures and real-time processing
# Supports asynchronous and synchronous invocation patterns
resource "aws_sns_topic_subscription" "lambda" {
  count = var.create_topic && length(var.lambda_subscriptions) > 0 ? length(var.lambda_subscriptions) : 0

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = "lambda"
  endpoint  = var.lambda_subscriptions[count.index].function_arn

  filter_policy   = var.lambda_subscriptions[count.index].filter_policy != null ? jsonencode(var.lambda_subscriptions[count.index].filter_policy) : null
  delivery_policy = var.lambda_subscriptions[count.index].delivery_policy != null ? jsonencode(var.lambda_subscriptions[count.index].delivery_policy) : null
}

# ============================================================================
# HTTP/HTTPS SUBSCRIPTIONS
# ============================================================================
# HTTP/HTTPS webhook subscriptions for external system integration
# Supports both HTTP and HTTPS endpoints with custom headers
# Enables integration with third-party services and APIs
resource "aws_sns_topic_subscription" "http" {
  count = var.create_topic && length(var.http_subscriptions) > 0 ? length(var.http_subscriptions) : 0

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = var.http_subscriptions[count.index].protocol
  endpoint  = var.http_subscriptions[count.index].endpoint

  filter_policy       = var.http_subscriptions[count.index].filter_policy != null ? jsonencode(var.http_subscriptions[count.index].filter_policy) : null
  delivery_policy     = var.http_subscriptions[count.index].delivery_policy != null ? jsonencode(var.http_subscriptions[count.index].delivery_policy) : null
  raw_message_delivery = var.http_subscriptions[count.index].raw_message_delivery

  # Confirmation timeout for subscription confirmation
  confirmation_timeout_in_minutes = var.http_subscriptions[count.index].confirmation_timeout_in_minutes
}

# ============================================================================
# APPLICATION SUBSCRIPTIONS
# ============================================================================
# Mobile application subscriptions for push notifications
# Supports iOS, Android, and other mobile platforms
# Enables direct mobile app notifications
resource "aws_sns_topic_subscription" "application" {
  count = var.create_topic && length(var.application_subscriptions) > 0 ? length(var.application_subscriptions) : 0

  topic_arn = aws_sns_topic.this[0].arn
  protocol  = "application"
  endpoint  = var.application_subscriptions[count.index].endpoint_arn

  filter_policy   = var.application_subscriptions[count.index].filter_policy != null ? jsonencode(var.application_subscriptions[count.index].filter_policy) : null
  delivery_policy = var.application_subscriptions[count.index].delivery_policy != null ? jsonencode(var.application_subscriptions[count.index].delivery_policy) : null
}

# ============================================================================
# FIFO TOPIC SUBSCRIPTIONS
# ============================================================================
# Subscriptions for FIFO topics with ordered delivery
# Maintains message ordering and exactly-once delivery
# Supports SQS FIFO queues as subscribers
resource "aws_sns_topic_subscription" "fifo_sqs" {
  count = var.create_fifo_topic && length(var.fifo_sqs_subscriptions) > 0 ? length(var.fifo_sqs_subscriptions) : 0

  topic_arn = aws_sns_topic.fifo[0].arn
  protocol  = "sqs"
  endpoint  = var.fifo_sqs_subscriptions[count.index].queue_arn

  filter_policy       = var.fifo_sqs_subscriptions[count.index].filter_policy != null ? jsonencode(var.fifo_sqs_subscriptions[count.index].filter_policy) : null
  raw_message_delivery = var.fifo_sqs_subscriptions[count.index].raw_message_delivery
}

# ============================================================================
# TOPIC DATA PROTECTION POLICY
# ============================================================================
# Data protection policy for sensitive data handling
# Provides data loss prevention and compliance controls
# Supports PII detection and redaction
resource "aws_sns_topic_data_protection_policy" "this" {
  count = var.create_topic && var.data_protection_policy != null ? 1 : 0

  arn    = aws_sns_topic.this[0].arn
  policy = var.data_protection_policy
}