# Complete Infrastructure Stack with IAM Integration
# This example shows how all modules work together with proper IAM integration

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC Infrastructure
module "vpc" {
  source = "../../modules/vpc"

  name_prefix             = var.name_prefix
  vpc_cidr_block          = "10.0.0.0/16"
  public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
  allowed_ips             = ["0.0.0.0/0"]

  tags = local.common_tags
}

# IAM Resources
module "iam" {
  source = "../../modules/iam"

  # Service roles for different AWS services
  roles = {
    "ec2-instance-role" = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
      inline_policies = {
        "s3-access" = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "s3:GetObject",
                "s3:PutObject"
              ]
              Resource = "${module.storage.s3_bucket_arn}/*"
            }
          ]
        })
      }
      description = "Role for EC2 instances with S3 and SSM access"
    }

    "ecs-execution-role" = {
      assume_role_policy = local.ecs_assume_role_policy
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      ]
      description = "Role for ECS task execution"
    }

    "ecs-task-role" = {
      assume_role_policy = local.ecs_assume_role_policy
      inline_policies = {
        "app-permissions" = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = [
                "s3:GetObject",
                "s3:PutObject"
              ]
              Resource = "${module.storage.s3_bucket_arn}/*"
            }
          ]
        })
      }
      description = "Role for ECS tasks with application permissions"
    }

    "eks-cluster-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
              Service = "eks.amazonaws.com"
            }
          }
        ]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      ]
      description = "Role for EKS cluster"
    }

    "eks-node-group-role" = {
      assume_role_policy = local.ec2_assume_role_policy
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
      description = "Role for EKS node group"
    }
  }

  # Application users
  users = {
    "app-user" = {
      create_access_key = true
      managed_policy_arns = [
        module.iam.policy_arns["s3-app-access"]
      ]
    }
  }

  # Custom policies
  policies = {
    "s3-app-access" = {
      description = "Application access to S3 bucket"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:ListBucket"
            ]
            Resource = module.storage.s3_bucket_arn
          },
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = "${module.storage.s3_bucket_arn}/*"
          }
        ]
      })
    }
  }

  tags = local.common_tags
}

# Storage Resources
module "storage" {
  source = "../../modules/storage"

  # S3 Configuration
  create_s3_bucket      = true
  s3_bucket_name        = "${var.name_prefix}-app-storage"
  s3_versioning_enabled = true
  s3_encryption_algorithm = "AES256"

  # S3 Lifecycle Rules
  s3_lifecycle_rules = [
    {
      id     = "transition_to_ia"
      status = "Enabled"
      expiration = null
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
    }
  ]

  # EFS Configuration
  create_efs              = true
  efs_name                = "${var.name_prefix}-shared-storage"
  efs_performance_mode    = "generalPurpose"
  efs_throughput_mode     = "bursting"
  efs_encrypted           = true

  vpc_id                  = module.vpc.vpc_id
  efs_subnet_ids          = module.vpc.private_subnet_ids
  efs_allowed_cidr_blocks = [module.vpc.vpc_cidr_block]

  # S3 Access Role
  create_s3_access_role = true
  s3_access_role_name   = "${var.name_prefix}-s3-access"
  s3_access_principals = [
    module.iam.role_arns["ec2-instance-role"],
    module.iam.role_arns["ecs-task-role"]
  ]

  tags = local.common_tags
}

# Load Balancer
module "alb" {
  source = "../../modules/elb"

  name       = "${var.name_prefix}-alb"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_groups = {
    "web-servers" = {
      port     = 80
      protocol = "HTTP"
      health_check = {
        path    = "/health"
        matcher = "200"
      }
    }
    "api-servers" = {
      port     = 8080
      protocol = "HTTP"
      health_check = {
        path    = "/api/health"
        matcher = "200"
      }
    }
  }

  listener_rules = {
    "http" = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type              = "forward"
        target_group_name = "web-servers"
      }
    }
  }

  listener_rules_additional = {
    "api-routing" = {
      listener_key = "http"
      priority     = 100
      action = {
        type              = "forward"
        target_group_name = "api-servers"
      }
      conditions = [
        {
          field  = "path-pattern"
          values = ["/api/*"]
        }
      ]
    }
  }

  tags = local.common_tags
}

# EC2 Auto Scaling Group
module "ec2" {
  source = "../../modules/ec2"

  name_prefix       = "${var.name_prefix}-web"
  ami_id           = var.ami_id
  instance_type    = "t3.medium"
  key_name         = var.key_name

  # Networking
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [module.vpc.default_security_group_id]

  # IAM Integration - Use existing role from IAM module
  iam_instance_profile_name = module.iam.instance_profiles["ec2-instance-role"].name

  # Load Balancer Integration
  target_group_arns = [module.alb.target_group_arns["web-servers"]]
  health_check_type = "ELB"

  # Auto Scaling Configuration
  desired_capacity = 3
  min_size         = 2
  max_size         = 6

  # Enable auto scaling policies
  enable_scaling_policies = true
  cpu_high_threshold     = 75
  cpu_low_threshold      = 25

  tags = local.common_tags
}

# ECS Cluster and Service
module "ecs" {
  source = "../../modules/ecs"

  cluster_name       = "${var.name_prefix}-ecs"
  container_insights = true

  # Service Configuration
  create_service = true
  service_name   = "api-service"
  desired_count  = 2

  # Task Configuration
  task_family     = "api-app"
  task_cpu        = 512
  task_memory     = 1024
  container_name  = "api"
  container_image = "nginx:latest"
  container_port  = 8080

  # IAM Integration - Use existing roles from IAM module
  execution_role_arn = module.iam.role_arns["ecs-execution-role"]
  task_role_arn     = module.iam.role_arns["ecs-task-role"]

  # Environment Variables
  environment_variables = [
    {
      name  = "S3_BUCKET"
      value = module.storage.s3_bucket_id
    },
    {
      name  = "EFS_MOUNT_POINT"
      value = "/mnt/efs"
    }
  ]

  # Networking
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  assign_public_ip = false

  # Load Balancer Integration
  target_group_arn = module.alb.target_group_arns["api-servers"]

  tags = local.common_tags
}

# EKS Cluster
module "eks" {
  source = "../../modules/eks"

  cluster_name       = "${var.name_prefix}-eks"
  kubernetes_version = "1.28"

  # Networking
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # IAM Integration - Use existing roles from IAM module
  cluster_service_role_arn = module.iam.role_arns["eks-cluster-role"]
  node_group_role_arn     = module.iam.role_arns["eks-node-group-role"]

  # Node Group Configuration
  instance_types   = ["t3.medium"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  tags = local.common_tags
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    Owner       = var.owner
  }

  ec2_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  ecs_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}