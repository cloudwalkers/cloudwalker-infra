# ============================================================================
# AWS S3 MODULE USAGE EXAMPLES
# ============================================================================
# Comprehensive examples showing different S3 bucket configurations
# These examples demonstrate various use cases and best practices
# ============================================================================

# ============================================================================
# EXAMPLE 1: BASIC S3 BUCKET
# ============================================================================
# Simple S3 bucket for application data storage
# Suitable for most standard storage scenarios

module "basic_bucket" {
  source = "./modules/s3"

  bucket_name        = "my-app-data-bucket"
  environment        = "dev"
  versioning_enabled = true
  encryption_algorithm = "AES256"

  tags = {
    Project = "MyApplication"
    Owner   = "DevTeam"
  }
}

# ============================================================================
# EXAMPLE 2: SECURE BUCKET WITH KMS ENCRYPTION
# ============================================================================
# Production-ready bucket with customer-managed encryption
# Recommended for sensitive data storage

module "secure_bucket" {
  source = "./modules/s3"

  bucket_name          = "company-sensitive-data"
  environment          = "prod"
  versioning_enabled   = true
  encryption_algorithm = "aws:kms"
  kms_key_id          = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  bucket_key_enabled   = true

  # Enhanced security settings
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = {
    Environment = "production"
    Compliance  = "SOC2"
    Encrypted   = "true"
  }
}

# ============================================================================
# EXAMPLE 3: BUCKET WITH LIFECYCLE MANAGEMENT
# ============================================================================
# Cost-optimized bucket with automated lifecycle transitions
# Ideal for data archival and long-term storage

module "archive_bucket" {
  source = "./modules/s3"

  bucket_name        = "company-document-archive"
  environment        = "prod"
  versioning_enabled = true

  # Comprehensive lifecycle rules
  lifecycle_rules = [
    {
      id     = "document_lifecycle"
      status = "Enabled"
      filter = {
        prefix = "documents/"
      }
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
        days = 2555  # 7 years retention
      }
      noncurrent_version_expiration = {
        days = 90
      }
      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    },
    {
      id     = "temp_files_cleanup"
      status = "Enabled"
      filter = {
        prefix = "temp/"
      }
      expiration = {
        days = 30
      }
    }
  ]

  tags = {
    Purpose    = "document-archive"
    Compliance = "required"
    Retention  = "7-years"
  }
}

# ============================================================================
# EXAMPLE 4: STATIC WEBSITE HOSTING
# ============================================================================
# S3 bucket configured for static website hosting
# Perfect for hosting static websites and SPAs

module "website_bucket" {
  source = "./modules/s3"

  bucket_name        = "my-company-website"
  environment        = "prod"
  versioning_enabled = false  # Not needed for static sites

  # Website configuration
  website_configuration = {
    index_document = "index.html"
    error_document = "error.html"
  }

  # CORS for web applications
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["https://mycompany.com", "https://www.mycompany.com"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  # Public access for website (carefully configured)
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  # Website access policy
  bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::my-company-website/*"
      }
    ]
  })

  tags = {
    Purpose = "static-website"
    Public  = "true"
  }
}

# ============================================================================
# EXAMPLE 5: DATA LAKE BUCKET
# ============================================================================
# Large-scale data lake with intelligent tiering
# Optimized for big data and analytics workloads

module "data_lake_bucket" {
  source = "./modules/s3"

  bucket_name          = "company-data-lake"
  environment          = "prod"
  versioning_enabled   = true
  encryption_algorithm = "aws:kms"

  # Intelligent tiering for cost optimization
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
    },
    {
      id     = "old_data_archival"
      status = "Enabled"
      filter = {
        prefix = "historical/"
      }
      transitions = [
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    }
  ]

  # Event notifications for data processing
  lambda_notifications = [
    {
      lambda_function_arn = "arn:aws:lambda:us-west-2:123456789012:function:process-data"
      events              = ["s3:ObjectCreated:*"]
      filter_prefix       = "raw-data/"
      filter_suffix       = ".json"
    }
  ]

  tags = {
    Purpose     = "data-lake"
    Analytics   = "enabled"
    Tiering     = "intelligent"
  }
}

# ============================================================================
# EXAMPLE 6: BACKUP BUCKET WITH CROSS-REGION REPLICATION
# ============================================================================
# Backup bucket with comprehensive disaster recovery
# Enterprise-grade backup and recovery solution

module "backup_bucket" {
  source = "./modules/s3"

  bucket_name          = "company-backup-primary"
  environment          = "prod"
  versioning_enabled   = true
  encryption_algorithm = "aws:kms"

  # Backup-optimized lifecycle
  lifecycle_rules = [
    {
      id     = "backup_lifecycle"
      status = "Enabled"
      transitions = [
        {
          days          = 1
          storage_class = "STANDARD_IA"
        },
        {
          days          = 30
          storage_class = "GLACIER"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      expiration = {
        days = 2555  # 7 years
      }
      noncurrent_version_transitions = [
        {
          days          = 30
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  # Access logging for compliance
  logging_configuration = {
    target_bucket = "company-access-logs"
    target_prefix = "backup-bucket-logs/"
  }

  tags = {
    Purpose     = "backup"
    Compliance  = "required"
    Retention   = "7-years"
    DR          = "enabled"
  }
}

# ============================================================================
# EXAMPLE 7: DEVELOPMENT BUCKET
# ============================================================================
# Development environment bucket with relaxed settings
# Cost-optimized for development and testing

module "dev_bucket" {
  source = "./modules/s3"

  bucket_name        = "myapp-dev-storage"
  environment        = "dev"
  versioning_enabled = false  # Cost optimization
  force_destroy      = true   # Allow easy cleanup

  # Simple lifecycle for cost control
  lifecycle_rules = [
    {
      id     = "dev_cleanup"
      status = "Enabled"
      expiration = {
        days = 30  # Auto-delete after 30 days
      }
      abort_incomplete_multipart_upload = {
        days_after_initiation = 1
      }
    }
  ]

  tags = {
    Environment   = "development"
    CostOptimized = "true"
    AutoCleanup   = "enabled"
  }
}

# ============================================================================
# EXAMPLE 8: MULTI-ENVIRONMENT SETUP
# ============================================================================
# Complete multi-environment storage solution
# Demonstrates environment-specific configurations

# Production Bucket
module "prod_app_bucket" {
  source = "./modules/s3"

  bucket_name          = "myapp-prod-data"
  environment          = "prod"
  versioning_enabled   = true
  encryption_algorithm = "aws:kms"

  lifecycle_rules = [
    {
      id     = "prod_lifecycle"
      status = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]

  tags = {
    Environment = "production"
    Criticality = "high"
    Backup      = "required"
  }
}

# Staging Bucket
module "staging_app_bucket" {
  source = "./modules/s3"

  bucket_name        = "myapp-staging-data"
  environment        = "staging"
  versioning_enabled = true

  lifecycle_rules = [
    {
      id     = "staging_lifecycle"
      status = "Enabled"
      expiration = {
        days = 90  # Shorter retention for staging
      }
    }
  ]

  tags = {
    Environment = "staging"
    Purpose     = "testing"
  }
}

# ============================================================================
# EXAMPLE 9: CONTENT DELIVERY BUCKET
# ============================================================================
# Bucket optimized for CDN and content delivery
# Configured for high-performance content serving

module "cdn_bucket" {
  source = "./modules/s3"

  bucket_name        = "myapp-cdn-assets"
  environment        = "prod"
  versioning_enabled = true

  # CORS for CDN access
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      max_age_seconds = 86400
    }
  ]

  # Lifecycle for asset management
  lifecycle_rules = [
    {
      id     = "asset_management"
      status = "Enabled"
      filter = {
        prefix = "assets/"
      }
      transitions = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]
    }
  ]

  tags = {
    Purpose = "cdn-assets"
    CDN     = "enabled"
  }
}