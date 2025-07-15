# AWS S3 Module

This Terraform module creates and manages AWS S3 buckets with comprehensive security, lifecycle management, and integration features.

## Features

- **Secure Storage**: Server-side encryption with AES256 or KMS
- **Versioning**: Object versioning for data protection and recovery
- **Lifecycle Management**: Automated transitions between storage classes
- **Public Access Blocking**: Comprehensive protection against accidental public exposure
- **Event Notifications**: Integration with Lambda, SNS, and SQS
- **Static Website Hosting**: Support for static website configuration
- **CORS Configuration**: Cross-origin resource sharing for web applications
- **Access Logging**: Audit trail for compliance and security monitoring
- **Bucket Policies**: Fine-grained access control with IAM policies

## Storage Classes

The module supports automatic lifecycle transitions between AWS S3 storage classes:

1. **Standard**: Frequently accessed data with low latency
2. **Standard-IA**: Infrequently accessed data with lower storage cost
3. **Intelligent Tiering**: Automatic cost optimization based on access patterns
4. **Glacier**: Long-term archival with retrieval times of minutes to hours
5. **Deep Archive**: Lowest cost archival with retrieval times of 12+ hours

## Usage Examples

### Basic S3 Bucket

```hcl
module "basic_bucket" {
  source = "./modules/s3"

  bucket_name        = "my-app-data-bucket"
  environment        = "prod"
  versioning_enabled = true

  tags = {
    Project = "MyApplication"
  }
}
```

### Secure Bucket with KMS Encryption

```hcl
module "secure_bucket" {
  source = "./modules/s3"

  bucket_name          = "sensitive-data-bucket"
  environment          = "prod"
  versioning_enabled   = true
  encryption_algorithm = "aws:kms"
  kms_key_id          = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Compliance = "SOC2"
    Encrypted  = "true"
  }
}
```

### Bucket with Lifecycle Management

```hcl
module "archive_bucket" {
  source = "./modules/s3"

  bucket_name        = "document-archive"
  environment        = "prod"
  versioning_enabled = true

  lifecycle_rules = [
    {
      id     = "document_lifecycle"
      status = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      expiration = {
        days = 2555  # 7 years
      }
      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]

  tags = {
    Purpose   = "archive"
    Retention = "7-years"
  }
}
```

### Static Website Hosting

```hcl
module "website_bucket" {
  source = "./modules/s3"

  bucket_name        = "my-static-website"
  environment        = "prod"
  versioning_enabled = false

  website_configuration = {
    index_document = "index.html"
    error_document = "error.html"
  }

  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://mycompany.com"]
      max_age_seconds = 3000
    }
  ]

  # Carefully configured public access for website
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::my-static-website/*"
      }
    ]
  })

  tags = {
    Purpose = "static-website"
  }
}
```

### Data Lake with Event Notifications

```hcl
module "data_lake" {
  source = "./modules/s3"

  bucket_name          = "company-data-lake"
  environment          = "prod"
  versioning_enabled   = true
  encryption_algorithm = "aws:kms"

  lifecycle_rules = [
    {
      id     = "intelligent_tiering"
      status = "Enabled"
      transitions = [
        {
          days          = 0
          storage_class = "INTELLIGENT_TIERING"
        }
      ]
    }
  ]

  lambda_notifications = [
    {
      lambda_function_arn = "arn:aws:lambda:us-west-2:123456789012:function:process-data"
      events              = ["s3:ObjectCreated:*"]
      filter_prefix       = "raw-data/"
      filter_suffix       = ".json"
    }
  ]

  tags = {
    Purpose   = "data-lake"
    Analytics = "enabled"
  }
}
```

## Input Variables

### General Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `bucket_name` | `string` | - | Name of the S3 bucket (globally unique) |
| `environment` | `string` | `"dev"` | Environment name for tagging |
| `tags` | `map(string)` | `{}` | Additional tags for resources |
| `create_bucket` | `bool` | `true` | Whether to create the bucket |
| `force_destroy` | `bool` | `false` | Allow deletion of non-empty bucket |

### Versioning and Encryption

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `versioning_enabled` | `bool` | `true` | Enable bucket versioning |
| `encryption_algorithm` | `string` | `"AES256"` | Encryption algorithm (AES256 or aws:kms) |
| `kms_key_id` | `string` | `null` | KMS key ID for encryption |
| `bucket_key_enabled` | `bool` | `true` | Enable S3 bucket key for KMS cost optimization |

### Public Access Block

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `block_public_acls` | `bool` | `true` | Block public ACLs |
| `block_public_policy` | `bool` | `true` | Block public bucket policies |
| `ignore_public_acls` | `bool` | `true` | Ignore public ACLs |
| `restrict_public_buckets` | `bool` | `true` | Restrict public bucket policies |

### Lifecycle Management

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lifecycle_rules` | `list(object)` | `[]` | List of lifecycle rules for automated data management |

### Notifications and Integration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lambda_notifications` | `list(object)` | `[]` | Lambda function notifications |
| `sns_notifications` | `list(object)` | `[]` | SNS topic notifications |
| `sqs_notifications` | `list(object)` | `[]` | SQS queue notifications |
| `bucket_policy` | `string` | `null` | JSON policy document for access control |

### Website and CORS

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `website_configuration` | `object` | `null` | Static website hosting configuration |
| `cors_rules` | `list(object)` | `[]` | CORS rules for cross-origin access |

### Logging

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `logging_configuration` | `object` | `null` | Access logging configuration |

## Outputs

### Bucket Information

| Output | Description |
|--------|-------------|
| `bucket_id` | ID of the S3 bucket |
| `bucket_arn` | ARN of the S3 bucket |
| `bucket_name` | Name of the S3 bucket |
| `bucket_domain_name` | Domain name of the bucket |
| `bucket_regional_domain_name` | Regional domain name |
| `bucket_hosted_zone_id` | Route 53 hosted zone ID |
| `bucket_region` | AWS region of the bucket |

### Website Hosting

| Output | Description |
|--------|-------------|
| `website_endpoint` | Website endpoint URL |
| `website_domain` | Website domain name |

### Configuration Status

| Output | Description |
|--------|-------------|
| `versioning_status` | Versioning status |
| `encryption_configuration` | Encryption configuration details |
| `public_access_block_configuration` | Public access block settings |

## Best Practices

### Security
- **Always enable encryption** for sensitive data
- **Use KMS customer-managed keys** for enhanced security
- **Keep public access blocked** unless specifically needed
- **Implement least privilege** access policies
- **Enable access logging** for audit trails

### Cost Optimization
- **Use lifecycle rules** to transition data to cheaper storage classes
- **Enable intelligent tiering** for automatic cost optimization
- **Set expiration policies** for temporary data
- **Clean up incomplete multipart uploads**
- **Use S3 bucket keys** with KMS for cost reduction

### Performance
- **Use appropriate request patterns** to avoid hot-spotting
- **Implement proper retry logic** for applications
- **Use multipart uploads** for large objects
- **Consider transfer acceleration** for global applications

### Compliance
- **Enable versioning** for data protection
- **Implement lifecycle policies** for retention requirements
- **Use access logging** for audit trails
- **Set up cross-region replication** for disaster recovery

## Integration Examples

### With CloudFront CDN

```hcl
module "cdn_bucket" {
  source = "./modules/s3"

  bucket_name = "my-cdn-assets"
  
  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      max_age_seconds = 86400
    }
  ]
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = module.cdn_bucket.bucket_regional_domain_name
    origin_id   = "S3-${module.cdn_bucket.bucket_name}"
  }
  # ... other CloudFront configuration
}
```

### With Lambda Processing

```hcl
module "processing_bucket" {
  source = "./modules/s3"

  bucket_name = "data-processing"
  
  lambda_notifications = [
    {
      lambda_function_arn = aws_lambda_function.processor.arn
      events              = ["s3:ObjectCreated:*"]
      filter_prefix       = "input/"
    }
  ]
}

resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.processing_bucket.bucket_arn
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |

## Resources Created

- `aws_s3_bucket` - The S3 bucket
- `aws_s3_bucket_versioning` - Versioning configuration
- `aws_s3_bucket_server_side_encryption_configuration` - Encryption settings
- `aws_s3_bucket_public_access_block` - Public access controls
- `aws_s3_bucket_lifecycle_configuration` - Lifecycle rules
- `aws_s3_bucket_notification` - Event notifications
- `aws_s3_bucket_policy` - Access policies
- `aws_s3_bucket_cors_configuration` - CORS rules
- `aws_s3_bucket_website_configuration` - Website hosting
- `aws_s3_bucket_logging` - Access logging

## License

This module is released under the MIT License.