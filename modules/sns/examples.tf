# ============================================================================
# AWS SNS MODULE USAGE EXAMPLES
# ============================================================================
# Comprehensive examples showing different SNS configurations
# These examples demonstrate various use cases and best practices
# ============================================================================

# ============================================================================
# EXAMPLE 1: BASIC SNS TOPIC WITH EMAIL NOTIFICATIONS
# ============================================================================
# Simple SNS topic for basic email notifications
# Suitable for alerts and operational notifications

module "basic_notifications" {
  source = "./modules/sns"

  topic_name   = "app-notifications"
  display_name = "Application Notifications"
  environment  = "dev"

  # Email subscriptions for team notifications
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
    Owner   = "DevTeam"
  }
}

# ============================================================================
# EXAMPLE 2: MULTI-CHANNEL ALERT SYSTEM
# ============================================================================
# Comprehensive alerting with multiple delivery channels
# Supports email, SMS, and webhook notifications

module "alert_system" {
  source = "./modules/sns"

  topic_name   = "critical-alerts"
  display_name = "Critical System Alerts"
  environment  = "prod"

  # Email notifications for team
  email_subscriptions = [
    {
      email = "oncall@company.com"
      filter_policy = {
        severity = ["critical"]
      }
    },
    {
      email = "team-lead@company.com"
      filter_policy = {
        severity = ["high", "critical"]
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

  # Webhook integration with external systems
  http_subscriptions = [
    {
      protocol = "https"
      endpoint = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
      filter_policy = {
        severity = ["medium", "high", "critical"]
      }
      raw_message_delivery = true
    },
    {
      protocol = "https"
      endpoint = "https://api.pagerduty.com/integration/v1/webhooks/sns"
      filter_policy = {
        severity = ["critical"]
      }
    }
  ]

  tags = {
    Environment = "production"
    Purpose     = "alerting"
    Critical    = "true"
  }
}

# ============================================================================
# EXAMPLE 3: EVENT-DRIVEN ARCHITECTURE WITH SQS AND LAMBDA
# ============================================================================
# SNS topic for microservices communication
# Integrates with SQS queues and Lambda functions

module "event_bus" {
  source = "./modules/sns"

  topic_name   = "application-events"
  display_name = "Application Event Bus"
  environment  = "prod"

  # SQS subscriptions for reliable processing
  sqs_subscriptions = [
    {
      queue_arn = "arn:aws:sqs:us-west-2:123456789012:order-processing-queue"
      filter_policy = {
        event_type = ["order_created", "order_updated"]
      }
      raw_message_delivery = true
      redrive_policy = {
        deadLetterTargetArn = "arn:aws:sqs:us-west-2:123456789012:order-processing-dlq"
        maxReceiveCount     = 3
      }
    },
    {
      queue_arn = "arn:aws:sqs:us-west-2:123456789012:inventory-queue"
      filter_policy = {
        event_type = ["inventory_update", "stock_alert"]
      }
    }
  ]

  # Lambda subscriptions for real-time processing
  lambda_subscriptions = [
    {
      function_arn = "arn:aws:lambda:us-west-2:123456789012:function:analytics-processor"
      filter_policy = {
        event_type = ["user_action", "page_view"]
      }
    },
    {
      function_arn = "arn:aws:lambda:us-west-2:123456789012:function:notification-sender"
      filter_policy = {
        event_type = ["user_signup", "password_reset"]
      }
    }
  ]

  tags = {
    Architecture = "event-driven"
    Purpose      = "microservices-communication"
  }
}

# ============================================================================
# EXAMPLE 4: FIFO TOPIC FOR ORDERED PROCESSING
# ============================================================================
# FIFO SNS topic for ordered message delivery
# Ensures message ordering and exactly-once delivery

module "ordered_events" {
  source = "./modules/sns"

  topic_name              = "financial-transactions"
  environment             = "prod"
  create_topic            = false
  create_fifo_topic       = true
  content_based_deduplication = true

  # FIFO SQS subscriptions for ordered processing
  fifo_sqs_subscriptions = [
    {
      queue_arn = "arn:aws:sqs:us-west-2:123456789012:transaction-processing.fifo"
      filter_policy = {
        transaction_type = ["payment", "refund"]
      }
      raw_message_delivery = true
    },
    {
      queue_arn = "arn:aws:sqs:us-west-2:123456789012:audit-log.fifo"
      raw_message_delivery = false
    }
  ]

  tags = {
    Environment = "production"
    Compliance  = "financial"
    Ordering    = "required"
  }
}

# ============================================================================
# EXAMPLE 5: SECURE ENCRYPTED TOPIC
# ============================================================================
# Encrypted SNS topic for sensitive data
# Uses customer-managed KMS key for encryption

module "secure_notifications" {
  source = "./modules/sns"

  topic_name            = "sensitive-alerts"
  environment           = "prod"
  create_topic          = false
  create_encrypted_topic = true
  kms_master_key_id     = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  # Secure email notifications
  email_subscriptions = [
    {
      email = "security@company.com"
      filter_policy = {
        alert_type = ["security_breach", "unauthorized_access"]
      }
    }
  ]

  # Secure SQS integration
  sqs_subscriptions = [
    {
      queue_arn = "arn:aws:sqs:us-west-2:123456789012:security-events-queue"
      raw_message_delivery = true
    }
  ]

  # Data protection policy for PII
  data_protection_policy = jsonencode({
    Name    = "SensitiveDataProtection"
    Version = "2021-06-01"
    Statement = [
      {
        Sid    = "DenyPublishWithPII"
        Effect = "Deny"
        Principal = "*"
        Action = "SNS:Publish"
        Resource = "*"
        Condition = {
          ForAnyValue:StringEquals = {
            "aws:RequestedRegion" = ["us-west-2"]
          }
        }
      }
    ]
  })

  tags = {
    Environment = "production"
    Compliance  = "SOC2"
    Encrypted   = "true"
  }
}

# ============================================================================
# EXAMPLE 6: MOBILE PUSH NOTIFICATIONS
# ============================================================================
# SNS topic for mobile application notifications
# Integrates with mobile platform endpoints

module "mobile_notifications" {
  source = "./modules/sns"

  topic_name   = "mobile-push-notifications"
  display_name = "Mobile App Notifications"
  environment  = "prod"

  # Application subscriptions for mobile platforms
  application_subscriptions = [
    {
      endpoint_arn = "arn:aws:sns:us-west-2:123456789012:app/GCM/MyAndroidApp/12345678-1234-1234-1234-123456789012"
      filter_policy = {
        platform = ["android"]
        priority = ["high", "normal"]
      }
    },
    {
      endpoint_arn = "arn:aws:sns:us-west-2:123456789012:app/APNS/MyiOSApp/87654321-4321-4321-4321-210987654321"
      filter_policy = {
        platform = ["ios"]
        priority = ["high", "normal"]
      }
    }
  ]

  tags = {
    Platform = "mobile"
    Purpose  = "push-notifications"
  }
}

# ============================================================================
# EXAMPLE 7: MONITORING AND OBSERVABILITY
# ============================================================================
# SNS topic with comprehensive delivery status logging
# Monitors message delivery success and failures

module "monitored_notifications" {
  source = "./modules/sns"

  topic_name   = "monitored-events"
  display_name = "Monitored Event Notifications"
  environment  = "prod"

  # Delivery status logging configuration
  lambda_success_feedback_role_arn         = "arn:aws:iam::123456789012:role/SNSSuccessFeedback"
  lambda_success_feedback_sample_rate      = 100
  lambda_failure_feedback_role_arn         = "arn:aws:iam::123456789012:role/SNSFailureFeedback"
  
  sqs_success_feedback_role_arn            = "arn:aws:iam::123456789012:role/SNSSuccessFeedback"
  sqs_success_feedback_sample_rate         = 50
  sqs_failure_feedback_role_arn            = "arn:aws:iam::123456789012:role/SNSFailureFeedback"
  
  http_success_feedback_role_arn           = "arn:aws:iam::123456789012:role/SNSSuccessFeedback"
  http_success_feedback_sample_rate        = 25
  http_failure_feedback_role_arn           = "arn:aws:iam::123456789012:role/SNSFailureFeedback"

  # Custom delivery policy for retry behavior
  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numMinDelayRetries = 0
        numNoDelayRetries  = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })

  # Lambda subscriptions with monitoring
  lambda_subscriptions = [
    {
      function_arn = "arn:aws:lambda:us-west-2:123456789012:function:event-processor"
    }
  ]

  # SQS subscriptions with monitoring
  sqs_subscriptions = [
    {
      queue_arn = "arn:aws:sqs:us-west-2:123456789012:processing-queue"
    }
  ]

  tags = {
    Monitoring = "enabled"
    Observability = "comprehensive"
  }
}

# ============================================================================
# EXAMPLE 8: MULTI-ENVIRONMENT SETUP
# ============================================================================
# Environment-specific SNS topics with different configurations
# Demonstrates environment-based customization

# Production Environment
module "prod_notifications" {
  source = "./modules/sns"

  topic_name   = "prod-application-events"
  display_name = "Production Application Events"
  environment  = "prod"

  # Production-grade configurations
  email_subscriptions = [
    {
      email = "prod-alerts@company.com"
      filter_policy = {
        severity = ["high", "critical"]
      }
    }
  ]

  sms_subscriptions = [
    {
      phone_number = "+1234567890"
      filter_policy = {
        severity = ["critical"]
      }
    }
  ]

  # Custom topic policy for production
  topic_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublishFromServices"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::123456789012:role/ProductionServiceRole",
            "arn:aws:iam::123456789012:role/MonitoringRole"
          ]
        }
        Action   = "SNS:Publish"
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = "production"
    Criticality = "high"
  }
}

# Development Environment
module "dev_notifications" {
  source = "./modules/sns"

  topic_name   = "dev-application-events"
  display_name = "Development Application Events"
  environment  = "dev"

  # Simplified configuration for development
  email_subscriptions = [
    {
      email = "dev-team@company.com"
    }
  ]

  tags = {
    Environment = "development"
    Purpose     = "testing"
  }
}

# ============================================================================
# EXAMPLE 9: DISASTER RECOVERY NOTIFICATIONS
# ============================================================================
# SNS topic for disaster recovery and business continuity
# Critical notifications with multiple redundant channels

module "disaster_recovery_alerts" {
  source = "./modules/sns"

  topic_name   = "disaster-recovery-alerts"
  display_name = "Disaster Recovery Alerts"
  environment  = "prod"

  # Multiple email channels for redundancy
  email_subscriptions = [
    {
      email = "dr-team@company.com"
      filter_policy = {
        alert_type = ["system_failure", "data_loss", "security_breach"]
      }
    },
    {
      email = "executives@company.com"
      filter_policy = {
        severity = ["critical"]
        impact   = ["business_critical"]
      }
    }
  ]

  # SMS for immediate notification
  sms_subscriptions = [
    {
      phone_number = "+1234567890"  # Primary on-call
      filter_policy = {
        severity = ["critical"]
      }
    },
    {
      phone_number = "+0987654321"  # Secondary on-call
      filter_policy = {
        severity = ["critical"]
      }
    }
  ]

  # External system integration
  http_subscriptions = [
    {
      protocol = "https"
      endpoint = "https://api.incident-management.com/webhooks/sns"
      filter_policy = {
        alert_type = ["system_failure", "security_breach"]
      }
    }
  ]

  tags = {
    Purpose      = "disaster-recovery"
    Criticality  = "business-critical"
    Redundancy   = "multi-channel"
  }
}