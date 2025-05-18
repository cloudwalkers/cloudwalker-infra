terraform {
  required_version = ">= 1.0.0"
  /*backend "s3" {
    bucket         = "cloudwalker-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
  }*/
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #version = "values(aws.version)"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}