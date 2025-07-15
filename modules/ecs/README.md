# ECS Module

This module creates AWS ECS (Elastic Container Service) infrastructure including ECS cluster, optional Fargate services, task definitions, and supporting resources like IAM roles and CloudWatch log groups.

## Features

- **ECS Cluster**: Configurable cluster with Container Insights support
- **Fargate Support**: Serverless container execution with FARGATE and FARGATE_SPOT
- **Task Definitions**: Complete task definition with container specifications
- **ECS Services**: Optional service creation with load balancer integration
- **IAM Roles**: Automatic creation of execution and task roles
- **CloudWatch Logging**: Integrated log group for container logs
- **Security Groups**: Automatic security group creation for services
- **Capacity Providers**: Support for FARGATE, FARGATE_SPOT, and EC2

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ECS Cluster                             │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │                ECS Service                          │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │    │
│  │  │   Task 1    │  │   Task 2    │  │   Task 3    │  │    │
│  │  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │  │    │
│  │  │ │Container│ │  │ │Container│ │  │ │Container│ │  │    │
│  │  │ │  App    │ │  │ │  App    │ │  │ │  App    │ │  │    │
│  │  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                CloudWatch Logs                             │
│              /ecs/cluster-name                              │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic ECS Cluster Only

```hcl
module "ecs_cluster" {
  source = "./modules/ecs"

  cluster_name       = "my-app-cluster"
  container_insights = true
  
  tags = {
    Environment = "production"
    Application = "my-app"
  }
}
```

### ECS Cluster with Fargate Service

```hcl
module "ecs_with_service" {
  source = "./modules/ecs"

  # Cluster Configuration
  cluster_name       = "web-app-cluster"
  container_insights = true

  # Service Configuration
  create_service = true
  service_name   = "web-service"
  desired_count  = 3

  # Task Configuration
  task_family     = "web-app"
  task_cpu        = 512
  task_memory     = 1024
  container_name  = "web-container"
  container_image = "nginx:latest"
  container_port  = 80

  # Networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Load Balancer Integration
  target_group_arn = module.alb.target_group_arns["web-servers"]

  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
```

### Advanced ECS Service with Custom Configuration

```hcl
module "api_service" {
  source = "./modules/ecs"

  # Cluster
  cluster_name       = "api-cluster"
  container_insights = true

  # Capacity Providers
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy = {
    base              = 2
    weight            = 100
    capacity_provider = "FARGATE"
  }

  # Service
  create_service           = true
  service_name            = "api-service"
  desired_count           = 5
  service_capacity_provider = "FARGATE"

  # Task Definition
  task_family     = "api-app"
  task_cpu        = 1024
  task_memory     = 2048
  container_name  = "api-container"
  container_image = "my-api:v1.2.3"
  container_port  = 8080

  # Environment Variables
  environment_variables = [
    {
      name  = "NODE_ENV"
      value = "production"
    },
    {
      name  = "API_PORT"
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

  # Load Balancer
  target_group_arn = module.alb.target_group_arns["api-servers"]

  # Logging
  log_retention_in_days = 30

  tags = {
    Environment = "production"
    Application = "api-service"
    Team        = "backend"
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the ECS cluster | `string` | n/a | yes |
| container_insights | Enable CloudWatch Container Insights | `bool` | `false` | no |
| capacity_providers | List of capacity providers | `list(string)` | `["FARGATE", "FARGATE_SPOT"]` | no |
| create_service | Whether to create an ECS service | `bool` | `false` | no |
| service_name | Name of the ECS service | `string` | `""` | no |
| desired_count | Desired number of tasks | `number` | `1` | no |
| task_family | Task definition family name | `string` | `"app"` | no |
| task_cpu | CPU units for the task | `number` | `256` | no |
| task_memory | Memory (MB) for the task | `number` | `512` | no |
| container_name | Name of the container | `string` | `"app"` | no |
| container_image | Docker image for the container | `string` | `"nginx:latest"` | no |
| container_port | Port exposed by the container | `number` | `80` | no |
| vpc_id | VPC ID for security groups | `string` | `""` | no |
| subnet_ids | List of subnet IDs for the service | `list(string)` | `[]` | no |
| environment_variables | Environment variables for the container | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the ECS cluster |
| cluster_arn | ARN of the ECS cluster |
| cluster_name | Name of the ECS cluster |
| service_id | ID of the ECS service |
| service_name | Name of the ECS service |
| task_definition_arn | ARN of the task definition |
| log_group_name | Name of the CloudWatch log group |
| execution_role_arn | ARN of the ECS execution role |
| task_role_arn | ARN of the ECS task role |

## Task Definition Features

- **Fargate Compatibility**: Optimized for serverless container execution
- **CloudWatch Logging**: Automatic log configuration
- **Environment Variables**: Support for runtime configuration
- **Resource Allocation**: Configurable CPU and memory limits
- **IAM Integration**: Separate execution and task roles

## Capacity Providers

The module supports three capacity provider types:

1. **FARGATE**: Fully managed serverless compute
2. **FARGATE_SPOT**: Cost-optimized with potential interruptions
3. **EC2**: Self-managed EC2 instances (requires additional setup)

## Security

- **IAM Roles**: Least privilege access for execution and task roles
- **Security Groups**: Automatic creation with minimal required access
- **VPC Integration**: Deploy in private subnets for enhanced security
- **Task Role**: Separate role for application-specific permissions

## Best Practices

1. **Resource Sizing**: Right-size CPU and memory for your workload
2. **Logging**: Use structured logging and appropriate retention periods
3. **Health Checks**: Configure meaningful health check endpoints
4. **Secrets Management**: Use AWS Secrets Manager or Parameter Store
5. **Networking**: Deploy services in private subnets
6. **Monitoring**: Enable Container Insights for detailed metrics
7. **Cost Optimization**: Use FARGATE_SPOT for non-critical workloads

## Cost Optimization

- **FARGATE_SPOT**: Up to 70% cost savings for fault-tolerant workloads
- **Right Sizing**: Monitor CPU/memory usage and adjust accordingly
- **Capacity Providers**: Mix FARGATE and FARGATE_SPOT based on requirements
- **Log Retention**: Set appropriate CloudWatch log retention periods

## Integration Examples

### With VPC Module
```hcl
module "vpc" {
  source = "./modules/vpc"
  # ... configuration
}

module "ecs" {
  source = "./modules/ecs"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  # ... other configuration
}
```

### With Load Balancer Module
```hcl
module "alb" {
  source = "./modules/elb"
  # ... configuration
}

module "ecs" {
  source = "./modules/ecs"
  
  target_group_arn = module.alb.target_group_arns["app-servers"]
  # ... other configuration
}
```