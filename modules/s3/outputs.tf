# ============================================================================
# AWS S3 MODULE OUTPUTS
# ============================================================================
# Output values for S3 bucket attributes and endpoints
# Used for integration with other modules and external references
# ============================================================================

# ============================================================================
# BUCKET IDENTIFICATION
# ============================================================================

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = var.create_bucket ? aws_s3_bucket.this[0].id : null
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = var.create_bucket ? aws_s3_bucket.this[0].arn : null
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = var.create_bucket ? aws_s3_bucket.this[0].bucket : null
}

# ============================================================================
# BUCKET ENDPOINTS AND DOMAINS
# ============================================================================

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = var.create_bucket ? aws_s3_bucket.this[0].bucket_domain_name : null
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = var.create_bucket ? aws_s3_bucket.this[0].bucket_regional_domain_name : null
}

output "bucket_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the S3 bucket"
  value       = var.create_bucket ? aws_s3_bucket.this[0].hosted_zone_id : null
}

output "bucket_region" {
  description = "AWS region where the S3 bucket is located"
  value       = var.create_bucket ? aws_s3_bucket.this[0].region : null
}

# ============================================================================
# WEBSITE HOSTING ENDPOINTS
# ============================================================================

output "website_endpoint" {
  description = "Website endpoint for static website hosting"
  value       = var.create_bucket && var.website_configuration != null ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
}

output "website_domain" {
  description = "Domain name for static website hosting"
  value       = var.create_bucket && var.website_configuration != null ? aws_s3_bucket_website_configuration.this[0].website_domain : null
}

# ============================================================================
# BUCKET CONFIGURATION STATUS
# ============================================================================

output "versioning_status" {
  description = "Versioning status of the S3 bucket"
  value       = var.create_bucket ? aws_s3_bucket_versioning.this[0].versioning_configuration[0].status : null
}

output "encryption_configuration" {
  description = "Server-side encryption configuration of the bucket"
  value = var.create_bucket ? {
    algorithm         = aws_s3_bucket_server_side_encryption_configuration.this[0].rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
    kms_master_key_id = aws_s3_bucket_server_side_encryption_configuration.this[0].rule[0].apply_server_side_encryption_by_default[0].kms_master_key_id
    bucket_key_enabled = aws_s3_bucket_server_side_encryption_configuration.this[0].rule[0].bucket_key_enabled
  } : null
}

output "public_access_block_configuration" {
  description = "Public access block configuration of the bucket"
  value = var.create_bucket ? {
    block_public_acls       = aws_s3_bucket_public_access_block.this[0].block_public_acls
    block_public_policy     = aws_s3_bucket_public_access_block.this[0].block_public_policy
    ignore_public_acls      = aws_s3_bucket_public_access_block.this[0].ignore_public_acls
    restrict_public_buckets = aws_s3_bucket_public_access_block.this[0].restrict_public_buckets
  } : null
}

# ============================================================================
# INTEGRATION OUTPUTS
# ============================================================================

output "bucket_policy" {
  description = "Bucket policy JSON document"
  value       = var.create_bucket && var.bucket_policy != null ? aws_s3_bucket_policy.this[0].policy : null
  sensitive   = true
}

output "lifecycle_rules_count" {
  description = "Number of lifecycle rules configured"
  value       = length(var.lifecycle_rules)
}

output "cors_rules_count" {
  description = "Number of CORS rules configured"
  value       = length(var.cors_rules)
}

output "notification_configurations" {
  description = "Summary of notification configurations"
  value = {
    lambda_notifications = length(var.lambda_notifications)
    sns_notifications    = length(var.sns_notifications)
    sqs_notifications    = length(var.sqs_notifications)
  }
}

# ============================================================================
# BUCKET ATTRIBUTES FOR REFERENCE
# ============================================================================

output "bucket_attributes" {
  description = "Complete bucket attributes for reference"
  value = var.create_bucket ? {
    id                         = aws_s3_bucket.this[0].id
    arn                        = aws_s3_bucket.this[0].arn
    bucket                     = aws_s3_bucket.this[0].bucket
    region                     = aws_s3_bucket.this[0].region
    domain_name                = aws_s3_bucket.this[0].bucket_domain_name
    regional_domain_name       = aws_s3_bucket.this[0].bucket_regional_domain_name
    hosted_zone_id             = aws_s3_bucket.this[0].hosted_zone_id
    versioning_enabled         = var.versioning_enabled
    encryption_algorithm       = var.encryption_algorithm
    force_destroy              = var.force_destroy
  } : null
}