# ============================================================================
# TERRAFORM AND PROVIDER VERSION CONSTRAINTS
# ============================================================================
# Centralized version management for all modules and root configuration
# This file defines the minimum required versions for Terraform and providers
# used across all modules in this infrastructure repository
# ============================================================================

terraform {
  # Minimum Terraform version required
  # Using 1.0.0+ ensures stable module syntax and features
  required_version = ">= 1.0.0"

  # Required providers for all modules
  required_providers {
    # AWS Provider - Primary cloud provider
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    # Random Provider - Used for generating unique identifiers
    # Required by: EFS module (creation tokens)
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }

    # Time Provider - Used for time-based resources and delays
    # Required by: Various modules for resource timing
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }

    # TLS Provider - Used for certificate and key generation
    # Required by: EKS module (cluster certificates)
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    # Kubernetes Provider - Used for EKS cluster configuration
    # Required by: EKS module (cluster resources)
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }

    # Helm Provider - Used for Kubernetes package management
    # Required by: EKS module (cluster add-ons)
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

# ============================================================================
# PROVIDER CONFIGURATIONS
# ============================================================================
# Default provider configurations that can be inherited by modules

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  # Default tags applied to all resources
  default_tags {
    tags = merge(
      {
        ManagedBy   = "Terraform"
        Repository  = "cloudwalker-infra"
        Project     = var.project_name
        Environment = var.environment
      },
      var.default_tags
    )
  }
}

# Random Provider Configuration
provider "random" {
  # No specific configuration needed
}

# Time Provider Configuration
provider "time" {
  # No specific configuration needed
}

# TLS Provider Configuration
provider "tls" {
  # No specific configuration needed
}

# Kubernetes Provider Configuration
# Note: This will be configured dynamically by the EKS module
provider "kubernetes" {
  # Configuration will be provided by EKS module outputs
}

# Helm Provider Configuration
# Note: This will be configured dynamically by the EKS module
provider "helm" {
  # Configuration will be provided by EKS module outputs
}