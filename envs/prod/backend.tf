# backend.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Use an appropriate version for your project
    }
  }

  # Configure the S3 backend
  backend "s3" {
    bucket         = "cloudwalker-terraform-state-prod" # Replace with your S3 bucket name
    key            = "us-east-1/prod/terraform.tfstate"     # Unique path for this specific project/environment's state
    region         = "us-east-1"                                # Replace with your AWS region
    encrypt        = true                                       # Ensures the state file is encrypted in S3
    dynamodb_table = "cloudwalker-terraform-prod-locks"               # Replace with your DynamoDB table name

    # Optional: If you use a specific AWS profile or role
    profile = "my-aws-profile"
    # role_arn = "arn:aws:iam::123456789012:role/TerraformExecutionRole"
    use_lockfile = false
    # IMPORTANT: Do NOT set use_lockfile = true if you intend to use DynamoDB for locking.
    # use_lockfile = false # This is the default if not specified, but explicitly setting it clarifies intent.
  }
}

# The AWS provider block is separate from the backend configuration
provider "aws" {
  region = "us-east-1" # This must match the region specified in the backend if you're deploying resources there
}

# Example resource to demonstrate it works
resource "aws_s3_bucket" "example" {
  bucket = "cloudwalker-terraform-state-prod" # Replace with a unique bucket name
  acl    = "private"
}