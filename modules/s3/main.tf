# ============================================================================
# AWS S3 (Simple Storage Service) MODULE
# ============================================================================
# This module creates and manages AWS S3 buckets for object storage
# with comprehensive security, lifecycle management, and access control.
# S3 provides:
# - Scalable object storage with 99.999999999% (11 9's) durability
# - Multiple storage classes for cost optimization
# - Versioning and lifecycle management
# - Server-side encryption and access control
# - Integration with other AWS services
# ============================================================================

# ============================================================================
# S3 BUCKET
# ============================================================================
# Primary S3 bucket for object storage
# Provides secure, scalable storage with configurable features
# Supports versioning, encryption, and lifecycle management
resource "aws_s3_bucket" "this" {
  count = var.create_bucket ? 1 : 0

  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name        = var.bucket_name
      Environment = var.environment
      Module      = "s3"
    }
  )
}

# ============================================================================
# BUCKET VERSIONING
# ============================================================================
# Object versioning for data protection and recovery
# Maintains multiple versions of objects for accidental deletion protection
# Essential for compliance and data integrity requirements
resource "aws_s3_bucket_versioning" "this" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }

  # Prevent versioning changes that could cause data loss
  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================================
# SERVER-SIDE ENCRYPTION
# ============================================================================
# Encryption at rest for all objects in the bucket
# Supports AWS managed keys (SSE-S3) and customer managed keys (SSE-KMS)
# Ensures data security and compliance requirements
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_algorithm
      kms_master_key_id = var.encryption_algorithm == "aws:kms" ? var.kms_key_id : null
    }
    # Enable S3 bucket key for KMS cost optimization
    bucket_key_enabled = var.encryption_algorithm == "aws:kms" ? var.bucket_key_enabled : null
  }
}

# ============================================================================
# PUBLIC ACCESS BLOCK
# ============================================================================
# Comprehensive public access prevention
# Blocks all forms of public access to prevent data exposure
# Critical security control for sensitive data protection
resource "aws_s3_bucket_public_access_block" "this" {
  count = var.create_bucket ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# ============================================================================
# LIFECYCLE CONFIGURATION
# ============================================================================
# Automated data lifecycle management for cost optimization
# Transitions objects between storage classes based on access patterns
# Supports expiration policies for data retention compliance
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.create_bucket && length(var.lifecycle_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      # Filter for specific prefixes or tags
      dynamic "filter" {
        for_each = rule.value.filter != null ? [rule.value.filter] : []
        content {
          prefix = filter.value.prefix

          dynamic "tag" {
            for_each = filter.value.tags != null ? filter.value.tags : {}
            content {
              key   = tag.key
              value = tag.value
            }
          }
        }
      }

      # Object expiration rules
      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days                         = expiration.value.days
          date                         = expiration.value.date
          expired_object_delete_marker = expiration.value.expired_object_delete_marker
        }
      }

      # Storage class transitions
      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          date          = transition.value.date
          storage_class = transition.value.storage_class
        }
      }

      # Non-current version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_version_expiration != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.days
        }
      }

      # Non-current version transitions
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_version_transitions
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # Abort incomplete multipart uploads
      dynamic "abort_incomplete_multipart_upload" {
        for_each = rule.value.abort_incomplete_multipart_upload != null ? [rule.value.abort_incomplete_multipart_upload] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }

  # Ensure bucket exists before creating lifecycle configuration
  depends_on = [aws_s3_bucket_versioning.this]
}

# ============================================================================
# BUCKET NOTIFICATION
# ============================================================================
# Event notifications for bucket operations
# Supports SNS, SQS, and Lambda function notifications
# Enables event-driven architectures and monitoring
resource "aws_s3_bucket_notification" "this" {
  count = var.create_bucket && (length(var.lambda_notifications) > 0 || length(var.sns_notifications) > 0 || length(var.sqs_notifications) > 0) ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  # Lambda function notifications
  dynamic "lambda_function" {
    for_each = var.lambda_notifications
    content {
      lambda_function_arn = lambda_function.value.lambda_function_arn
      events              = lambda_function.value.events
      filter_prefix       = lambda_function.value.filter_prefix
      filter_suffix       = lambda_function.value.filter_suffix
    }
  }

  # SNS topic notifications
  dynamic "topic" {
    for_each = var.sns_notifications
    content {
      topic_arn     = topic.value.topic_arn
      events        = topic.value.events
      filter_prefix = topic.value.filter_prefix
      filter_suffix = topic.value.filter_suffix
    }
  }

  # SQS queue notifications
  dynamic "queue" {
    for_each = var.sqs_notifications
    content {
      queue_arn     = queue.value.queue_arn
      events        = queue.value.events
      filter_prefix = queue.value.filter_prefix
      filter_suffix = queue.value.filter_suffix
    }
  }
}

# ============================================================================
# BUCKET POLICY
# ============================================================================
# IAM policy for bucket access control
# Defines permissions for bucket and object operations
# Supports cross-account access and service integration
resource "aws_s3_bucket_policy" "this" {
  count = var.create_bucket && var.bucket_policy != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id
  policy = var.bucket_policy

  # Ensure public access block is configured first
  depends_on = [aws_s3_bucket_public_access_block.this]
}

# ============================================================================
# BUCKET CORS CONFIGURATION
# ============================================================================
# Cross-Origin Resource Sharing configuration
# Enables web applications to access bucket from different domains
# Essential for web-based applications and CDN integration
resource "aws_s3_bucket_cors_configuration" "this" {
  count = var.create_bucket && length(var.cors_rules) > 0 ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# ============================================================================
# BUCKET WEBSITE CONFIGURATION
# ============================================================================
# Static website hosting configuration
# Enables S3 bucket to serve static web content
# Supports custom error pages and routing rules
resource "aws_s3_bucket_website_configuration" "this" {
  count = var.create_bucket && var.website_configuration != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  dynamic "index_document" {
    for_each = var.website_configuration.index_document != null ? [var.website_configuration.index_document] : []
    content {
      suffix = index_document.value
    }
  }

  dynamic "error_document" {
    for_each = var.website_configuration.error_document != null ? [var.website_configuration.error_document] : []
    content {
      key = error_document.value
    }
  }

  dynamic "redirect_all_requests_to" {
    for_each = var.website_configuration.redirect_all_requests_to != null ? [var.website_configuration.redirect_all_requests_to] : []
    content {
      host_name = redirect_all_requests_to.value.host_name
      protocol  = redirect_all_requests_to.value.protocol
    }
  }
}

# ============================================================================
# BUCKET LOGGING
# ============================================================================
# Access logging configuration for audit and compliance
# Records all requests made to the bucket
# Essential for security monitoring and compliance requirements
resource "aws_s3_bucket_logging" "this" {
  count = var.create_bucket && var.logging_configuration != null ? 1 : 0

  bucket = aws_s3_bucket.this[0].id

  target_bucket = var.logging_configuration.target_bucket
  target_prefix = var.logging_configuration.target_prefix
}