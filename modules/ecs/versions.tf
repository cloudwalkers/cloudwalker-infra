terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #version = "values(aws.version)"
      version = "~> 5.0"
    }
  }
}