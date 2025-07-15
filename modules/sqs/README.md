# AWS SQS Module

This Terraform module creates and manages AWS Simple Queue Service (SQS) resources, providing reliable message queuing for distributed applications.

## Features

- **Standard SQS Queues**: Traditional message queues with at-least-once delivery
- **FIFO Queues**: First-In-First-Out queues with exactly-once processing and message ordering
- **Dead Letter Queues**: Automatic handling of failed messages for both standard and FIFO queues
- **Encryption Support**: Server-side encryption with AWS managed or customer managed KMS keys
- **Access Control**: Custom IAM policies for fine-grained queue access control
- **Comprehensive Configuration**: Full control over queue attributes and behavior

## Queue Types

### Standard Queues
- **Use Case**: General message processing, high throughput scenarios
- **Delivery**: At-least-once delivery (messages may be delivered more than once)
- **Ordering**: Best-effort ordering (messages may arrive out of order)
- **Throughput**: Nearly unlimited transactions per second

### FIFO Queues
- **Use Case**: Applications requiring strict message ordering and exactly-once processing
- **Delivery**: Exactly-once processing (no duplicates)
- **Ordering**: Strict FIFO ordering within message groups
- **Throughput**: Up to 300 transactions per second (or 3,000 with batching)

## Usage Examples

### Basic Standard Queue

```hcl
module "basic_queue" {
  source = "./modules/sqs"

  queue_name  = "my-processing-queue"
  environment = "prod"

  visibility_timeout_seconds = 30
  message_retention_seconds  = 1209600 # 14 days

  tags = {
    Project = "MyApplication"
  }
}
```

### Queue with Dead Letter Queue

```hcl
module "reliable_queue" {
  source = "./modules/sqs"

  queue_name  = "order-processing"
  environment = "prod"

  # Enable dead letter queue
  create_dlq        = true
  max_receive_count = 3

  # Long polling for efficiency
  receive_wait_time_seconds = 20

  tags = {
    Project = "ECommerce"
  }
}
```

### FIFO Queue for Ordered Processing

```hcl
module "fifo_queue" {
  source = "./modules/sqs"

  queue_name  = "financial-transactions"
  environment = "prod"

  # Create FIFO queue
  create_queue      = false
  create_fifo_queue = true
  create_fifo_dlq   = true

  # FIFO configuration
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"

  max_receive_count = 5

  tags = {
    Project = "FinancialSystem"
  }
}
```

### Encrypted Queue with Custom Policy

```hcl
module "secure_queue" {
  source = "./modules/sqs"

  queue_name  = "sensitive-data"
  environment = "prod"

  # Encryption
  kms_master_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Custom access policy
  queue_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:role/ProcessorRole"
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
    Compliance = "SOC2"
  }
}
```

## Input Variables

### General Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `queue_name` | `string` | - | Name of the SQS queue |
| `environment` | `string` | `"dev"` | Environment name for tagging |
| `tags` | `map(string)` | `{}` | Additional tags for resources |

### Queue Creation Flags

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_queue` | `bool` | `true` | Create standard SQS queue |
| `create_dlq` | `bool` | `false` | Create dead letter queue for standard queue |
| `create_fifo_queue` | `bool` | `false` | Create FIFO SQS queue |
| `create_fifo_dlq` | `bool` | `false` | Create dead letter queue for FIFO queue |

### Queue Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `delay_seconds` | `number` | `0` | Message delivery delay (0-900 seconds) |
| `max_message_size` | `number` | `262144` | Maximum message size in bytes (1024-262144) |
| `message_retention_seconds` | `number` | `1209600` | Message retention period (60-1209600 seconds) |
| `receive_wait_time_seconds` | `number` | `0` | Long polling wait time (0-20 seconds) |
| `visibility_timeout_seconds` | `number` | `30` | Message visibility timeout (0-43200 seconds) |

### Dead Letter Queue Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `max_receive_count` | `number` | `3` | Max receives before moving to DLQ (1-1000) |
| `dlq_message_retention_seconds` | `number` | `1209600` | DLQ message retention period |

### FIFO Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `content_based_deduplication` | `bool` | `false` | Enable content-based deduplication |
| `deduplication_scope` | `string` | `"queue"` | Deduplication scope (`queue` or `messageGroup`) |
| `fifo_throughput_limit` | `string` | `"perQueue"` | Throughput quota (`perQueue` or `perMessageGroupId`) |

### Security Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `kms_master_key_id` | `string` | `null` | KMS key ID for encryption |
| `queue_policy` | `string` | `null` | IAM policy for standard queue |
| `fifo_queue_policy` | `string` | `null` | IAM policy for FIFO queue |

## Outputs

### Standard Queue Outputs

| Output | Description |
|--------|-------------|
| `queue_id` | URL of the standard SQS queue |
| `queue_arn` | ARN of the standard SQS queue |
| `queue_url` | URL of the standard SQS queue |
| `queue_name` | Name of the standard SQS queue |

### Dead Letter Queue Outputs

| Output | Description |
|--------|-------------|
| `dlq_id` | URL of the dead letter queue |
| `dlq_arn` | ARN of the dead letter queue |
| `dlq_url` | URL of the dead letter queue |
| `dlq_name` | Name of the dead letter queue |

### FIFO Queue Outputs

| Output | Description |
|--------|-------------|
| `fifo_queue_id` | URL of the FIFO SQS queue |
| `fifo_queue_arn` | ARN of the FIFO SQS queue |
| `fifo_queue_url` | URL of the FIFO SQS queue |
| `fifo_queue_name` | Name of the FIFO SQS queue |

### FIFO Dead Letter Queue Outputs

| Output | Description |
|--------|-------------|
| `fifo_dlq_id` | URL of the FIFO dead letter queue |
| `fifo_dlq_arn` | ARN of the FIFO dead letter queue |
| `fifo_dlq_url` | URL of the FIFO dead letter queue |
| `fifo_dlq_name` | Name of the FIFO dead letter queue |

## Best Practices

### Message Processing
- Use **long polling** (`receive_wait_time_seconds > 0`) to reduce costs and improve efficiency
- Set appropriate **visibility timeout** based on your processing time requirements
- Implement **dead letter queues** for production workloads to handle failed messages

### FIFO Queues
- Use **message group IDs** to enable parallel processing while maintaining order within groups
- Enable **content-based deduplication** to automatically handle duplicate messages
- Consider **throughput limits** when designing high-volume FIFO applications

### Security
- Use **KMS encryption** for sensitive data
- Implement **least privilege** access policies
- Monitor queue access with **CloudTrail** logging

### Cost Optimization
- Use **long polling** to reduce the number of empty receives
- Set appropriate **message retention** periods to avoid unnecessary storage costs
- Consider **FIFO queues** only when ordering is strictly required

## Integration Examples

### With Lambda Functions

```hcl
# SQS Queue
module "processing_queue" {
  source = "./modules/sqs"

  queue_name                = "lambda-processing"
  receive_wait_time_seconds = 20
  create_dlq               = true
}

# Lambda function triggered by SQS
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = module.processing_queue.queue_arn
  function_name    = aws_lambda_function.processor.arn
  batch_size       = 10
}
```

### With Auto Scaling

```hcl
# Queue for scaling decisions
module "scaling_queue" {
  source = "./modules/sqs"

  queue_name = "auto-scaling-trigger"
}

# CloudWatch alarm based on queue depth
resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name          = "sqs-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessages"
  namespace           = "AWS/SQS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    QueueName = module.scaling_queue.queue_name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |

## Resources Created

- `aws_sqs_queue` - Standard and/or FIFO queues
- `aws_sqs_queue_policy` - Queue access policies (optional)

## License

This module is released under the MIT License.