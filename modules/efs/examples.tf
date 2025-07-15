# ============================================================================
# AWS EFS MODULE USAGE EXAMPLES
# ============================================================================
# Comprehensive examples showing different EFS configurations
# These examples demonstrate various use cases and best practices
# ============================================================================

# ============================================================================
# EXAMPLE 1: BASIC EFS FILE SYSTEM
# ============================================================================
# Simple EFS file system for shared application storage
# Suitable for most standard file sharing scenarios

module "basic_efs" {
  source = "./modules/efs"

  name                = "app-shared-storage"
  environment         = "dev"
  vpc_id              = "vpc-12345678"
  subnet_ids          = ["subnet-12345678", "subnet-87654321"]
  allowed_cidr_blocks = ["10.0.0.0/16"]

  tags = {
    Project = "MyApplication"
    Owner   = "DevTeam"
  }
}

# ============================================================================
# EXAMPLE 2: HIGH-PERFORMANCE EFS
# ============================================================================
# EFS optimized for high I/O workloads
# Ideal for data processing and analytics applications

module "high_performance_efs" {
  source = "./modules/efs"

  name                   = "data-processing-storage"
  environment            = "prod"
  performance_mode       = "maxIO"
  throughput_mode        = "provisioned"
  provisioned_throughput = 500  # 500 MiB/s

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.ec2.security_group_id]

  # Cost optimization with lifecycle policy
  lifecycle_policy = {
    transition_to_ia                    = "AFTER_30_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Environment = "production"
    Workload    = "data-processing"
    Performance = "high"
  }
}

# ============================================================================
# EXAMPLE 3: SECURE EFS WITH ENCRYPTION
# ============================================================================
# Fully encrypted EFS with customer-managed KMS key
# Recommended for sensitive data storage

module "secure_efs" {
  source = "./modules/efs"

  name        = "secure-file-storage"
  environment = "prod"
  encrypted   = true
  kms_key_id  = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.app.security_group_id]

  # Enable backups for compliance
  backup_enabled = true

  # Cross-region replication for disaster recovery
  replication_configuration = {
    destination_region = "us-east-1"
    kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/87654321-4321-4321-4321-210987654321"
  }

  tags = {
    Environment = "production"
    Compliance  = "SOC2"
    Encrypted   = "true"
    DR          = "enabled"
  }
}

# ============================================================================
# EXAMPLE 4: EFS WITH ACCESS POINTS
# ============================================================================
# Multi-tenant EFS with application-specific access points
# Provides fine-grained access control for different applications

module "multi_tenant_efs" {
  source = "./modules/efs"

  name        = "multi-tenant-storage"
  environment = "prod"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.app1.security_group_id, module.app2.security_group_id]

  # Application-specific access points
  access_points = {
    app1 = {
      posix_user = {
        gid = 1001
        uid = 1001
      }
      root_directory = {
        path = "/app1"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
      tags = {
        Application = "app1"
      }
    }
    app2 = {
      posix_user = {
        gid = 1002
        uid = 1002
      }
      root_directory = {
        path = "/app2"
        creation_info = {
          owner_gid   = 1002
          owner_uid   = 1002
          permissions = "750"
        }
      }
      tags = {
        Application = "app2"
      }
    }
    shared = {
      root_directory = {
        path = "/shared"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "755"
        }
      }
      tags = {
        Purpose = "shared-storage"
      }
    }
  }

  tags = {
    Architecture = "multi-tenant"
    AccessControl = "enabled"
  }
}

# ============================================================================
# EXAMPLE 5: CONTAINER STORAGE FOR EKS
# ============================================================================
# EFS optimized for Kubernetes persistent volumes
# Configured for container workloads and EKS integration

module "eks_storage" {
  source = "./modules/efs"

  name        = "eks-persistent-storage"
  environment = "prod"

  vpc_id                     = module.eks.vpc_id
  subnet_ids                 = module.eks.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]

  # Optimized for container workloads
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Access points for different namespaces
  access_points = {
    default = {
      root_directory = {
        path = "/default"
        creation_info = {
          owner_gid   = 0
          owner_uid   = 0
          permissions = "755"
        }
      }
    }
    production = {
      root_directory = {
        path = "/production"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "750"
        }
      }
    }
    staging = {
      root_directory = {
        path = "/staging"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
    }
  }

  tags = {
    Platform    = "kubernetes"
    Integration = "eks"
    Storage     = "persistent-volumes"
  }
}

# ============================================================================
# EXAMPLE 6: DEVELOPMENT EFS
# ============================================================================
# Cost-optimized EFS for development environments
# Simplified configuration for development use

module "dev_efs" {
  source = "./modules/efs"

  name        = "dev-shared-files"
  environment = "dev"

  vpc_id              = module.dev_vpc.vpc_id
  subnet_ids          = module.dev_vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  # Cost optimization settings
  encrypted      = false  # Cost optimization for dev
  backup_enabled = false  # Not needed for dev

  # Aggressive lifecycle policy for cost control
  lifecycle_policy = {
    transition_to_ia = "AFTER_7_DAYS"
  }

  tags = {
    Environment   = "development"
    CostOptimized = "true"
  }
}

# ============================================================================
# EXAMPLE 7: WEB APPLICATION SHARED STORAGE
# ============================================================================
# EFS for web application shared assets and uploads
# Configured for web server integration

module "web_app_storage" {
  source = "./modules/efs"

  name        = "webapp-shared-storage"
  environment = "prod"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.web_servers.security_group_id]

  # Access points for different content types
  access_points = {
    uploads = {
      root_directory = {
        path = "/uploads"
        creation_info = {
          owner_gid   = 33  # www-data
          owner_uid   = 33  # www-data
          permissions = "755"
        }
      }
      tags = {
        ContentType = "user-uploads"
      }
    }
    assets = {
      root_directory = {
        path = "/assets"
        creation_info = {
          owner_gid   = 33  # www-data
          owner_uid   = 33  # www-data
          permissions = "755"
        }
      }
      tags = {
        ContentType = "static-assets"
      }
    }
    cache = {
      root_directory = {
        path = "/cache"
        creation_info = {
          owner_gid   = 33  # www-data
          owner_uid   = 33  # www-data
          permissions = "755"
        }
      }
      tags = {
        ContentType = "application-cache"
      }
    }
  }

  # Lifecycle policy for cache optimization
  lifecycle_policy = {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Application = "web-application"
    Purpose     = "shared-storage"
  }
}

# ============================================================================
# EXAMPLE 8: BACKUP AND ARCHIVE STORAGE
# ============================================================================
# EFS for backup and long-term archive storage
# Optimized for infrequent access patterns

module "backup_storage" {
  source = "./modules/efs"

  name        = "backup-archive-storage"
  environment = "prod"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.backup_servers.security_group_id]

  # Optimized for backup workloads
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Aggressive lifecycle policy for cost optimization
  lifecycle_policy = {
    transition_to_ia = "AFTER_7_DAYS"
  }

  # Enable backups for compliance
  backup_enabled = true

  # Cross-region replication for disaster recovery
  replication_configuration = {
    destination_region = "us-east-1"
  }

  tags = {
    Purpose     = "backup-archive"
    Compliance  = "required"
    CostOptimized = "true"
  }
}

# ============================================================================
# EXAMPLE 9: MACHINE LEARNING DATASET STORAGE
# ============================================================================
# High-performance EFS for ML training data
# Optimized for data science and ML workloads

module "ml_dataset_storage" {
  source = "./modules/efs"

  name                   = "ml-training-datasets"
  environment            = "prod"
  performance_mode       = "maxIO"
  throughput_mode        = "provisioned"
  provisioned_throughput = 1000  # 1000 MiB/s for ML workloads

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.ml_cluster.security_group_id]

  # Access points for different datasets
  access_points = {
    training_data = {
      root_directory = {
        path = "/training"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "755"
        }
      }
      tags = {
        DataType = "training"
      }
    }
    validation_data = {
      root_directory = {
        path = "/validation"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "755"
        }
      }
      tags = {
        DataType = "validation"
      }
    }
    models = {
      root_directory = {
        path = "/models"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "755"
        }
      }
      tags = {
        DataType = "trained-models"
      }
    }
  }

  tags = {
    Workload    = "machine-learning"
    Performance = "high-throughput"
    DataScience = "enabled"
  }
}