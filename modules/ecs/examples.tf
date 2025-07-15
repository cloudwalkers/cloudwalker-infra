# Example 1: Basic ECS Cluster Only
/*
module "basic_cluster" {
  source = "./modules/ecs"

  cluster_name       = "basic-cluster"
  container_insights = false

  tags = {
    Environment = "development"
    Purpose     = "testing"
  }
}
*/

# Example 2: Simple Web Application with Fargate
/*
module "web_app_ecs" {
  source = "./modules/ecs"

  # Cluster Configuration
  cluster_name       = "web-app-cluster"
  container_insights = true

  # Service Configuration
  create_service = true
  service_name   = "web-service"
  desired_count  = 2

  # Task Configuration
  task_family     = "web-app"
  task_cpu        = 256
  task_memory     = 512
  container_name  = "nginx"
  container_image = "nginx:latest"
  container_port  = 80

  # Networking
  vpc_id           = "vpc-12345678"
  subnet_ids       = ["subnet-12345678", "subnet-87654321"]
  assign_public_ip = true

  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
*/

# Example 3: API Service with Custom Configuration
/*
module "api_service" {
  source = "./modules/ecs"

  # Cluster
  cluster_name       = "api-cluster"
  container_insights = true

  # Capacity Providers with mixed strategy
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }

  # Service
  create_service           = true
  service_name            = "api-service"
  desired_count           = 4
  service_capacity_provider = "FARGATE"

  # Task Definition
  task_family     = "api-app"
  task_cpu        = 512
  task_memory     = 1024
  container_name  = "api-container"
  container_image = "my-api:v2.1.0"
  container_port  = 8080

  # Environment Variables
  environment_variables = [
    {
      name  = "NODE_ENV"
      value = "production"
    },
    {
      name  = "PORT"
      value = "8080"
    },
    {
      name  = "LOG_LEVEL"
      value = "info"
    }
  ]

  # Networking
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  assign_public_ip = false

  # Load Balancer Integration
  target_group_arn = module.alb.target_group_arns["api-servers"]

  # Extended log retention
  log_retention_in_days = 30

  tags = {
    Environment = "production"
    Application = "api-service"
    Team        = "backend"
    Version     = "v2.1.0"
  }
}
*/

# Example 4: Microservices Architecture
/*
# Frontend Service
module "frontend_service" {
  source = "./modules/ecs"

  cluster_name       = "microservices-cluster"
  container_insights = true

  create_service = true
  service_name   = "frontend-service"
  desired_count  = 3

  task_family     = "frontend"
  task_cpu        = 256
  task_memory     = 512
  container_name  = "frontend"
  container_image = "my-frontend:latest"
  container_port  = 3000

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  target_group_arn = module.alb.target_group_arns["frontend"]

  tags = {
    Environment = "production"
    Service     = "frontend"
    Team        = "frontend"
  }
}

# Backend API Service
module "backend_service" {
  source = "./modules/ecs"

  cluster_name       = "microservices-cluster"
  container_insights = true

  create_service = true
  service_name   = "backend-service"
  desired_count  = 5

  task_family     = "backend"
  task_cpu        = 512
  task_memory     = 1024
  container_name  = "backend"
  container_image = "my-backend:latest"
  container_port  = 8080

  environment_variables = [
    {
      name  = "DATABASE_URL"
      value = "postgresql://db.internal:5432/myapp"
    },
    {
      name  = "REDIS_URL"
      value = "redis://cache.internal:6379"
    }
  ]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  target_group_arn = module.alb.target_group_arns["backend"]

  tags = {
    Environment = "production"
    Service     = "backend"
    Team        = "backend"
  }
}
*/

# Example 5: Development Environment with Spot Instances
/*
module "dev_ecs" {
  source = "./modules/ecs"

  cluster_name       = "dev-cluster"
  container_insights = false  # Cost optimization

  # Use Spot instances for cost savings
  capacity_providers = ["FARGATE_SPOT"]
  default_capacity_provider_strategy = {
    base              = 0
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }

  create_service           = true
  service_name            = "dev-app"
  desired_count           = 1
  service_capacity_provider = "FARGATE_SPOT"

  # Minimal resources for development
  task_family     = "dev-app"
  task_cpu        = 256
  task_memory     = 512
  container_name  = "app"
  container_image = "my-app:dev"
  container_port  = 3000

  environment_variables = [
    {
      name  = "NODE_ENV"
      value = "development"
    },
    {
      name  = "DEBUG"
      value = "true"
    }
  ]

  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_subnet_ids
  assign_public_ip = true  # For development access

  # Short log retention for cost savings
  log_retention_in_days = 3

  tags = {
    Environment  = "development"
    CostOptimized = "true"
    AutoShutdown = "enabled"
  }
}
*/

# Example 6: High-Performance Computing Service
/*
module "compute_service" {
  source = "./modules/ecs"

  cluster_name       = "compute-cluster"
  container_insights = true

  create_service = true
  service_name   = "compute-service"
  desired_count  = 2

  # High-performance task configuration
  task_family     = "compute-intensive"
  task_cpu        = 4096  # 4 vCPUs
  task_memory     = 8192  # 8 GB RAM
  container_name  = "compute-app"
  container_image = "my-compute-app:latest"
  container_port  = 8080

  environment_variables = [
    {
      name  = "WORKER_THREADS"
      value = "4"
    },
    {
      name  = "MEMORY_LIMIT"
      value = "7GB"
    }
  ]

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Extended log retention for analysis
  log_retention_in_days = 90

  tags = {
    Environment = "production"
    Workload    = "compute-intensive"
    Team        = "data-science"
  }
}
*/

# Example 7: Multi-Environment Setup
/*
# Production Environment
module "prod_ecs" {
  source = "./modules/ecs"

  cluster_name       = "prod-cluster"
  container_insights = true

  create_service = true
  service_name   = "prod-app"
  desired_count  = 6

  task_family     = "prod-app"
  task_cpu        = 1024
  task_memory     = 2048
  container_name  = "app"
  container_image = "my-app:v1.0.0"
  container_port  = 8080

  vpc_id     = module.prod_vpc.vpc_id
  subnet_ids = module.prod_vpc.private_subnet_ids

  log_retention_in_days = 90

  tags = {
    Environment = "production"
    Criticality = "high"
  }
}

# Staging Environment
module "staging_ecs" {
  source = "./modules/ecs"

  cluster_name       = "staging-cluster"
  container_insights = true

  create_service = true
  service_name   = "staging-app"
  desired_count  = 2

  task_family     = "staging-app"
  task_cpu        = 512
  task_memory     = 1024
  container_name  = "app"
  container_image = "my-app:staging"
  container_port  = 8080

  vpc_id     = module.staging_vpc.vpc_id
  subnet_ids = module.staging_vpc.private_subnet_ids

  log_retention_in_days = 14

  tags = {
    Environment = "staging"
    Purpose     = "testing"
  }
}
*/