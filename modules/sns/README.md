# AWS SNS Module

This Terraform module creates and manages AWS Simple Notification Service (SNS) topics and subscriptions for reliable pub/sub messaging and notifications.

## Features

- **Standard Topics**: Traditional pub/sub messaging with multiple delivery protocols
- **FIFO Topics**: First-In-First-Out topics with exactly-once delivery and message ordering
- **Multiple Protocols**: Email, SMS, SQS, Lambda, HTTP/HTTPS, and mobile push notifications
- **Message Filtering**: Attribute-based message filtering for targeted delivery
- **Encryption Support**: Server-side encryption with AWS managed or customer managed KMS keys
- **Delivery Status Logging**: Comprehensive monitoring of message delivery success and failures
- **Dead Letter Queue Support**: Failed message handling for reliable processing
- **Data Protection**: PII detection and data loss prevention policies
- **Access Control**: Fine-grained IAM policies for topic and subscription management

## Supported Protocols

### Email
- **Use Case**: Human notifications, alerts, and reports
- **Features**: HTML/text formatting, subscription confirmation required
- **Best For**: Operational alerts, weekly reports, user notifications

### SMS
- **Use Case**: Critical alerts and mobile notifications
- **Features**: International support, character limits apply
- **Best For**: Critical system alerts, two-factor authentication

### SQS
- **Use Case**: Reliable message processing and decoupling
- **Features**: Dead letter queue support, message persistence
- **Best For**: Microservices communication, batch processing

### Lambda
- **Use Case**: Serverless event processing
- **Features**: Automatic scaling, real-time processing
- **Best For**: Real-time analytics, automated responses

### HTTP/HTTPS
- **Use Case**: Webhook integrations with external systems
- **Features**: Custom headers, retry policies, confirmation required
- **Best For**: Third-party integrations, Slack notifications, PagerDuty

### Mobile Push
- **Use Case**: Mobile application notifications
- **Features**: Platform-specific formatting (iOS, Android)
- **Best For**: User engagement, app notifications

## Usage Examples

### Basic Email Notifications

```hcl
module "basic_notifications" {
  source = "./modules/sns"

  topic_name   = "app-notifications"
  display_name = "Application Notifications"
  environment  = "prod"

  email_subscriptions = [
    {
      email = "admin@company.com"
    },
    {
      email = "devops@company.com"
      filter_policy = {
        severity = ["high", "critical"]
      }
    }
  ]

  tags = {
    Project = "MyApplication"
  }
}
```

### Multi-Channel Alert System

```hcl
module "alert_system" {
  source = "./modules/sns"

  topic_name   = "critical-alerts"
  display_name = "Critical System Alerts"
  environment  = "prod"

  # Email notifications
  email_subscriptions = [
    {
      email = "oncall@company.com"
      filter_policy = {
        severity = ["critical"]
      }
    }
  ]

  # SMS for critical alerts
  sms_subscriptions = [
    {
      phone_number = "+1234567890"
      filter_policy = {
        severity = ["critical"]
        service  = ["database", "payment"]
      }
    }
  ]

  # Slack webhook integration
  http_subscriptions = [
    {
      protocol = "https"
      endpoint = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
      filter_policy = {
        severity = ["medium", "high", "critical"]
      }
      raw_message_delivery = true
    }
  ]

  tags = {
    Purpose = "alerting"
  }
}
```

### Event-Driven Architecture

```hcl
module "event_bus" {
  source = "./modules/sns"

  topic_name   = "application-events"
  display_name = "Application Event Bus"
  environment  = "prod"

  # SQS subscriptions for reliable processing
  sqs_subscriptions = [
    {
      queue_arn = module.order_queue.queue_arn
      filter_policy = {
        event_type = ["order_created", "order_updated"]
      }
      raw_message_delivery = true
      redrive_policy = {
        deadLetterTargetArn = module.order_dlq.queue_arn
        maxReceiveCount     = 3
      }
    }
  ]

  # Lambda subscriptions for real-time processing
  lambda_subscriptions = [
    {
      function_arn = module.analytics_function.function_arn
      filter_policy = {
        event_type = ["user_action", "page_view"]
      }
    }
  ]

  tags = {
    Architecture = "event-driven"
  }
}
```

### FIFO Topic for Ordered Processing

```hcl
module "ordered_events" {
  source = "./modules/sns"

  topic_name                  = "financial-transactions"
  environment                 = "prod"
  create_topic                = false
  create_fifo_topic           = true
  content_based_deduplication = true

  fifo_sqs_subscriptions = [
    {
      queue_arn = module.transaction_queue.fifo_queue_arn
      filter_policy = {
        transaction_type = ["payment", "refund"]
      }
      raw_message_delivery = true
    }
  ]

  tags = {
    Compliance = "financial"
    Ordering   = "required"
  }
}
```

### Secure Encrypted Topic

```hcl
module "secure_notifications" {
  source = "./modules/sns"

  topic_name             = "sensitive-alerts"
  environment            = "prod"
  create_topic           = false
  create_encrypted_topic = true
  kms_master_key_id      = module.kms.key_arn

  email_subscriptions = [
    {
      email = "security@company.com"
      filter_policy = {
        alert_type = ["security_breach", "unauthorized_access"]
      }
    }
  ]

  # Data protection policy
  data_protection_policy = jsonencode({
    Name    = "SensitiveDataProtection"
    Version = "2021-06-01"
    Statement = [
      {
        Sid       = "DenyPublishWithPII"
        Effect    = "Deny"
        Principal = "*"
        Action    = "SNS:Publish"
        Resource  = "*"
        Condition = {
          ForAnyValue:StringEquals = {
            "aws:RequestedRegion" = ["us-west-2"]
          }
        }
      }
    ]
  })

  tags = {
    Compliance = "SOC2"
    Encrypted  = "true"
  }
}
```

### Mobile Push Notifications

```hcl
module "mobile_notifications" {
  source = "./modules/sns"

  topic_name   = "mobile-push-notifications"
  display_name = "Mobile App Notifications"
  environment  = "prod"

  application_subscriptions = [
    {
      endpoint_arn = aws_sns_platform_endpoint.android.arn
      filter_policy = {
        platform = ["android"]
        priority = ["high", "normal"]
      }
    },
    {
      endpoint_arn = aws_sns_platform_endpoint.ios.arn
      filter_policy = {
        platform = ["ios"]
        priority = ["high", "normal"]
      }
    }
  ]

  tags = {
    Platform = "mobile"
  }
}
```

## Input Variables

### General Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `topic_name` | `string` | - | Name of the SNS topic |
| `environment` | `string` | `"dev"` | Environment name for tagging |
| `tags` | `map(string)` | `{}` | Additional tags for resources |
| `display_name` | `string` | `null` | Display name for the topic |

### Topic Creation Flags

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_topic` | `bool` | `true` | Create standard SNS topic |
| `create_fifo_topic` | `bool` | `false` | Create FIFO SNS topic |
| `create_encrypted_topic` | `bool` | `false` | Create encrypted SNS topic |

### Topic Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `topic_policy` | `string` | `null` | JSON policy for topic access control |
| `delivery_policy` | `string` | `null` | JSON delivery policy for retry behavior |
| `content_based_deduplication` | `bool` | `false` | Enable content-based deduplication for FIFO |
| `kms_master_key_id` | `string` | `null` | KMS key ID for encryption |

### Subscription Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `email_subscriptions` | `list(object)` | `[]` | List of email subscriptions |
| `sms_subscriptions` | `list(object)` | `[]` | List of SMS subscriptions |
| `sqs_subscriptions` | `list(object)` | `[]` | List of SQS subscriptions |
| `lambda_subscriptions` | `list(object)` | `[]` | List of Lambda subscriptions |
| `http_subscriptions` | `list(object)` | `[]` | List of HTTP/HTTPS subscriptions |
| `application_subscriptions` | `list(object)` | `[]` | List of mobile app subscriptions |
| `fifo_sqs_subscriptions` | `list(object)` | `[]` | List of FIFO SQS subscriptions |

### Delivery Status Logging

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lambda_success_feedback_role_arn` | `string` | `null` | IAM role for Lambda success feedback |
| `lambda_success_feedback_sample_rate` | `number` | `null` | Sample rate for Lambda success feedback (0-100) |
| `sqs_success_feedback_role_arn` | `string` | `null` | IAM role for SQS success feedback |
| `http_success_feedback_role_arn` | `string` | `null` | IAM role for HTTP success feedback |

### Data Protection

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `data_protection_policy` | `string` | `null` | JSON data protection policy |

## Outputs

### Topic Information

| Output | Description |
|--------|-------------|
| `topic_arn` | ARN of the SNS topic |
| `topic_id` | ID of the SNS topic |
| `topic_name` | Name of the SNS topic |
| `fifo_topic_arn` | ARN of the FIFO SNS topic |
| `encrypted_topic_arn` | ARN of the encrypted SNS topic |

### Subscription Information

| Output | Description |
|--------|-------------|
| `email_subscription_arns` | List of email subscription ARNs |
| `sms_subscription_arns` | List of SMS subscription ARNs |
| `sqs_subscription_arns` | List of SQS subscription ARNs |
| `lambda_subscription_arns` | List of Lambda subscription ARNs |
| `http_subscription_arns` | List of HTTP subscription ARNs |

### Configuration Details

| Output | Description |
|--------|-------------|
| `subscription_counts` | Count of subscriptions by type |
| `topic_configuration` | Complete topic configuration |
| `topic_attributes` | All topic attributes for reference |

## Message Filtering

SNS supports message filtering using subscription filter policies. Messages are delivered only if they match the filter criteria.

### Filter Policy Examples

```json
{
  "severity": ["high", "critical"],
  "service": ["database", "payment"],
  "region": ["us-west-2"]
}
```

### Numeric Matching

```json
{
  "price": [{"numeric": [">=", 100]}],
  "quantity": [{"numeric": ["<", 10]}]
}
```

### String Matching

```json
{
  "event_type": [{"prefix": "order_"}],
  "customer_type": [{"anything-but": ["test"]}]
}
```

## Best Practices

### Security
- **Use encryption** for sensitive data with customer-managed KMS keys
- **Implement least privilege** access policies for topics and subscriptions
- **Enable data protection policies** for PII detection and prevention
- **Use HTTPS endpoints** for webhook subscriptions

### Reliability
- **Configure dead letter queues** for SQS subscriptions
- **Set appropriate retry policies** in delivery policies
- **Monitor delivery status** with CloudWatch metrics
- **Use FIFO topics** when message ordering is critical

### Cost Optimization
- **Use message filtering** to reduce unnecessary deliveries
- **Monitor subscription usage** and remove unused subscriptions
- **Choose appropriate delivery protocols** based on use case
- **Set reasonable retry limits** to avoid excessive charges

### Performance
- **Use SQS subscriptions** for high-throughput scenarios
- **Implement proper error handling** in Lambda subscribers
- **Use raw message delivery** when message metadata isn't needed
- **Consider fan-out patterns** for scalable architectures

## Integration Examples

### With CloudWatch Alarms

```hcl
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [module.alert_system.topic_arn]
}
```

### With Lambda Functions

```hcl
resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = module.event_bus.topic_arn
}
```

### With SQS Queues

```hcl
resource "aws_sqs_queue_policy" "sns_policy" {
  queue_url = aws_sqs_queue.queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "sqs:SendMessage"
        Resource = aws_sqs_queue.queue.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = module.event_bus.topic_arn
          }
        }
      }
    ]
  })
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |

## Resources Created

- `aws_sns_topic` - SNS topics (standard, FIFO, encrypted)
- `aws_sns_topic_subscription` - Topic subscriptions for various protocols
- `aws_sns_topic_data_protection_policy` - Data protection policies

## License

This module is released under the MIT License.