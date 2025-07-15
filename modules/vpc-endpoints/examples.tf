# ============================================================================
# AWS VPC ENDPOINTS MODULE USAGE EXAMPLES
# ============================================================================
# Comprehensive examples showing different VPC endpoint configurations
# These examples demonstrate various use cases and best practices
# ============================================================================

# ============================================================================
# EXAMPLE 1: BASIC S3 AND DYNAMODB GATEWAY ENDPOINTS
# ============================================================================
# Simple gateway endpoints for cost-effective access to S3 and DynamoDB
# No additional charges for data processing or hourly usage

module "basic_gateway_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "basic"
  environment = "dev"
  vpc_id      = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
    dynamodb = {
      service_name      = "com.amazonaws.us-west-2.dynamodb"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
  }

  tags = {
    Project = "BasicInfrastructure"
    Purpose = "cost-optimization"
  }
}

# ============================================================================
# EXAMPLE 2: COMPREHENSIVE INTERFACE ENDPOINTS FOR EC2 MANAGEMENT
# ============================================================================
# Interface endpoints for EC2 instance management without internet access
# Includes SSM, EC2, and CloudWatch endpoints for complete management

module "ec2_management_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "ec2-mgmt"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  # Create default security group
  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  endpoints = {
    ec2 = {
      service_name        = "com.amazonaws.us-west-2.ec2"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ssm = {
      service_name        = "com.amazonaws.us-west-2.ssm"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ssmmessages = {
      service_name        = "com.amazonaws.us-west-2.ssmmessages"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ec2messages = {
      service_name        = "com.amazonaws.us-west-2.ec2messages"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    logs = {
      service_name        = "com.amazonaws.us-west-2.logs"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    monitoring = {
      service_name        = "com.amazonaws.us-west-2.monitoring"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Environment = "production"
    Purpose     = "ec2-management"
    Security    = "private-access"
  }
}

# ============================================================================
# EXAMPLE 3: CONTAINER WORKLOAD ENDPOINTS (ECS/EKS)
# ============================================================================
# VPC endpoints for containerized workloads
# Includes ECR, ECS, and supporting services

module "container_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "container"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  endpoints = {
    # ECR endpoints for container image access
    ecr_api = {
      service_name        = "com.amazonaws.us-west-2.ecr.api"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ecr_dkr = {
      service_name        = "com.amazonaws.us-west-2.ecr.dkr"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    
    # ECS endpoints for container orchestration
    ecs = {
      service_name        = "com.amazonaws.us-west-2.ecs"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ecs_agent = {
      service_name        = "com.amazonaws.us-west-2.ecs-agent"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ecs_telemetry = {
      service_name        = "com.amazonaws.us-west-2.ecs-telemetry"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }

    # Supporting services
    s3 = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
    logs = {
      service_name        = "com.amazonaws.us-west-2.logs"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Environment = "production"
    Workload    = "containers"
    Platform    = "ecs-eks"
  }
}

# ============================================================================
# EXAMPLE 4: SERVERLESS ENDPOINTS (LAMBDA)
# ============================================================================
# VPC endpoints for serverless workloads
# Includes Lambda and supporting services

module "serverless_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "serverless"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  endpoints = {
    lambda = {
      service_name        = "com.amazonaws.us-west-2.lambda"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    
    # Supporting services for Lambda
    s3 = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
    dynamodb = {
      service_name      = "com.amazonaws.us-west-2.dynamodb"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
    
    # Secrets and configuration
    secrets_manager = {
      service_name        = "com.amazonaws.us-west-2.secretsmanager"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    kms = {
      service_name        = "com.amazonaws.us-west-2.kms"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    
    # Messaging services
    sns = {
      service_name        = "com.amazonaws.us-west-2.sns"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    sqs = {
      service_name        = "com.amazonaws.us-west-2.sqs"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Environment = "production"
    Workload    = "serverless"
    Platform    = "lambda"
  }
}

# ============================================================================
# EXAMPLE 5: SECURE ENDPOINTS WITH CUSTOM POLICIES
# ============================================================================
# VPC endpoints with restrictive access policies
# Demonstrates fine-grained access control

module "secure_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "secure"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  endpoints = {
    s3_restricted = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
      
      # Restrictive policy allowing access only to specific buckets
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = "*"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:ListBucket"
            ]
            Resource = [
              "arn:aws:s3:::company-prod-data/*",
              "arn:aws:s3:::company-prod-data",
              "arn:aws:s3:::company-prod-logs/*",
              "arn:aws:s3:::company-prod-logs"
            ]
          }
        ]
      })
    }
    
    secrets_manager_restricted = {
      service_name        = "com.amazonaws.us-west-2.secretsmanager"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
      
      # Policy restricting access to specific secrets
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = "*"
            Action = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:DescribeSecret"
            ]
            Resource = "arn:aws:secretsmanager:us-west-2:*:secret:prod/*"
          }
        ]
      })
    }
  }

  tags = {
    Environment = "production"
    Security    = "restricted-access"
    Compliance  = "required"
  }
}

# ============================================================================
# EXAMPLE 6: MONITORING AND OBSERVABILITY ENDPOINTS
# ============================================================================
# VPC endpoints with comprehensive monitoring
# Includes CloudWatch Events for endpoint state monitoring

module "monitored_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "monitored"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  # Enable endpoint monitoring
  enable_endpoint_monitoring = true
  monitoring_sns_topic_arn   = module.alerts.topic_arn

  endpoints = {
    logs = {
      service_name        = "com.amazonaws.us-west-2.logs"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
      tags = {
        Critical = "true"
      }
    }
    monitoring = {
      service_name        = "com.amazonaws.us-west-2.monitoring"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
      tags = {
        Critical = "true"
      }
    }
    events = {
      service_name        = "com.amazonaws.us-west-2.events"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Environment = "production"
    Monitoring  = "enabled"
    Alerting    = "sns"
  }
}

# ============================================================================
# EXAMPLE 7: MULTI-REGION ENDPOINT SETUP
# ============================================================================
# VPC endpoints configured for multi-region applications
# Demonstrates region-specific service names

module "multi_region_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "multi-region"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  endpoints = {
    # Primary region services
    s3_primary = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
      tags = {
        Region = "us-west-2"
        Type   = "primary"
      }
    }
    
    # Cross-region replication support
    s3_backup_region = {
      service_name        = "com.amazonaws.us-east-1.s3"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = false  # Avoid DNS conflicts
      tags = {
        Region = "us-east-1"
        Type   = "backup"
      }
    }
    
    # Regional services
    ssm = {
      service_name        = "com.amazonaws.us-west-2.ssm"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Environment = "production"
    Architecture = "multi-region"
    DR          = "enabled"
  }
}

# ============================================================================
# EXAMPLE 8: DEVELOPMENT ENVIRONMENT ENDPOINTS
# ============================================================================
# Cost-optimized endpoints for development environments
# Minimal set of endpoints for basic functionality

module "dev_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "dev"
  environment = "dev"
  vpc_id      = module.dev_vpc.vpc_id

  # Use auto-accept for simplicity
  auto_accept = true

  endpoints = {
    # Essential gateway endpoints (no additional cost)
    s3 = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
    }
    dynamodb = {
      service_name      = "com.amazonaws.us-west-2.dynamodb"
      vpc_endpoint_type = "Gateway"
    }
    
    # Minimal interface endpoints for development
    ssm = {
      service_name        = "com.amazonaws.us-west-2.ssm"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.dev_vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Environment   = "development"
    CostOptimized = "true"
    Purpose       = "basic-connectivity"
  }
}

# ============================================================================
# EXAMPLE 9: ENTERPRISE ENDPOINTS WITH CUSTOM DNS
# ============================================================================
# Enterprise-grade endpoint setup with custom DNS resolution
# Includes Route 53 resolver rules for advanced DNS management

module "enterprise_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "enterprise"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  # Enable custom DNS resolver rules
  create_resolver_rules = true
  
  resolver_rules = {
    custom_s3 = {
      domain_name = "s3.internal.company.com"
      rule_type   = "FORWARD"
      target_ips = [
        {
          ip   = "10.0.1.100"
          port = 53
        }
      ]
      tags = {
        Service = "s3"
        Type    = "custom-dns"
      }
    }
  }

  endpoints = {
    s3 = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
    
    # Critical enterprise services
    kms = {
      service_name        = "com.amazonaws.us-west-2.kms"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    secrets_manager = {
      service_name        = "com.amazonaws.us-west-2.secretsmanager"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ssm = {
      service_name        = "com.amazonaws.us-west-2.ssm"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Environment = "production"
    Tier        = "enterprise"
    DNS         = "custom-resolution"
    Compliance  = "required"
  }
}