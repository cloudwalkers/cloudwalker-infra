# ============================================================================
# ECS CLUSTER RESOURCES
# ============================================================================
# ECS cluster provides the compute environment for running containerized applications
# Supports both Fargate (serverless) and EC2 launch types
# Includes monitoring, logging, and capacity provider configuration
# ============================================================================

# ECS Cluster
# Central management unit for containerized applications
# Provides compute capacity through Fargate or EC2 instances
# Enables service discovery, load balancing, and auto scaling
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  # Execute Command Configuration
  # Enables secure shell access to running containers for debugging
  # Logs all commands executed for security and compliance
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.ecs.name
      }
    }
  }

  # Container Insights
  # Provides detailed monitoring and observability for containers
  # Collects metrics on CPU, memory, network, and storage utilization
  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.tags, {
    Name      = var.cluster_name
    Purpose   = "ECS cluster for containerized applications"
    ManagedBy = "terraform"
    Module    = "ecs"
  })
}

# ECS Cluster Capacity Providers
# Defines the compute capacity available to the cluster
# Supports Fargate (serverless) and EC2 (managed instances) capacity
# Enables automatic scaling and cost optimization strategies
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  # Available capacity providers for the cluster
  # FARGATE: Serverless compute, pay per task
  # FARGATE_SPOT: Cost-optimized serverless with potential interruptions
  # EC2: Self-managed instances with more control
  capacity_providers = var.capacity_providers

  # Default strategy for task placement when no specific strategy is defined
  # Base: Minimum number of tasks to run on this capacity provider
  # Weight: Relative proportion of tasks to place on this capacity provider
  default_capacity_provider_strategy {
    base              = var.default_capacity_provider_strategy.base
    weight            = var.default_capacity_provider_strategy.weight
    capacity_provider = var.default_capacity_provider_strategy.capacity_provider
  }
}

# ============================================================================
# LOGGING RESOURCES
# ============================================================================
# CloudWatch log group centralizes container logs for monitoring and debugging
# Provides structured logging with configurable retention policies
# Essential for troubleshooting and compliance requirements
# ============================================================================

# CloudWatch Log Group
# Centralized logging destination for all ECS tasks in the cluster
# Provides structured log aggregation with configurable retention
# Essential for monitoring, debugging, and compliance
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge(var.tags, {
    Name      = "/ecs/${var.cluster_name}"
    Purpose   = "Log group for ECS cluster ${var.cluster_name}"
    ManagedBy = "terraform"
    Module    = "ecs"
  })
}

# ============================================================================
# ECS SERVICE RESOURCES
# ============================================================================
# ECS service manages the desired state of running tasks
# Handles task placement, health checks, and integration with load balancers
# Provides high availability and automatic recovery of failed tasks
# ============================================================================

# ECS Service
# Manages long-running tasks and ensures desired count is maintained
# Integrates with load balancers for traffic distribution
# Provides service discovery and health monitoring
resource "aws_ecs_service" "this" {
  count = var.create_service ? 1 : 0

  name            = var.service_name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[0].arn
  desired_count   = var.desired_count

  # Capacity Provider Strategy
  # Defines how tasks are distributed across capacity providers
  # Weight determines the relative proportion of tasks on each provider
  capacity_provider_strategy {
    capacity_provider = var.service_capacity_provider
    weight            = 100  # 100% of tasks on this capacity provider
  }

  # Network Configuration (required for Fargate)
  # Defines VPC networking settings for tasks
  # Security groups control network access to tasks
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_service[0].id]
    assign_public_ip = var.assign_public_ip  # Required for public subnet tasks
  }

  # Load Balancer Integration
  # Registers tasks with load balancer target groups
  # Enables health checks and traffic distribution
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # Service Dependencies
  # Ensures capacity providers are configured before service creation
  depends_on = [aws_ecs_cluster_capacity_providers.this]

  tags = merge(var.tags, {
    Name      = var.service_name
    Purpose   = "ECS service for ${var.service_name}"
    ManagedBy = "terraform"
    Module    = "ecs"
  })
}

# ECS Task Definition
# Defines the blueprint for running containers as tasks
# Specifies container images, resource requirements, and networking
# Acts as a template for launching containers in the ECS service
resource "aws_ecs_task_definition" "this" {
  count = var.create_service ? 1 : 0

  family                   = var.task_family
  requires_compatibilities = ["FARGATE"]  # Serverless container execution
  network_mode             = "awsvpc"     # Required for Fargate, provides ENI per task
  cpu                      = var.task_cpu    # CPU units (1024 = 1 vCPU)
  memory                   = var.task_memory # Memory in MB

  # IAM Roles for Task Execution and Application
  # Execution role: Used by ECS agent to pull images and write logs
  # Task role: Used by application code to access AWS services
  execution_role_arn = var.create_iam_roles ? aws_iam_role.ecs_execution[0].arn : var.execution_role_arn
  task_role_arn     = var.create_iam_roles ? aws_iam_role.ecs_task[0].arn : var.task_role_arn

  # Container Definitions
  # JSON specification of containers to run in the task
  # Includes image, ports, logging, and environment configuration
  container_definitions = jsonencode([
    {
      name  = var.container_name
      image = var.container_image

      # Port Mappings
      # Defines which ports the container exposes
      # Required for load balancer integration
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      # Logging Configuration
      # Sends container logs to CloudWatch for monitoring
      # Enables centralized log aggregation and analysis
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      # Environment Variables
      # Runtime configuration for the container
      # Allows dynamic configuration without rebuilding images
      environment = var.environment_variables

      # Essential Container
      # If this container stops, the entire task stops
      essential = true
    }
  ])

  tags = merge(var.tags, {
    Name      = var.task_family
    Purpose   = "Task definition for ${var.task_family}"
    ManagedBy = "terraform"
    Module    = "ecs"
  })
}

# ============================================================================
# SECURITY GROUP RESOURCES
# ============================================================================
# Security groups control network access to ECS tasks
# Acts as a virtual firewall for container networking
# Essential for securing containerized applications
# ============================================================================

# ECS Service Security Group
# Controls network access to ECS tasks running in the service
# Allows inbound traffic on the container port and all outbound traffic
# Should be customized based on application security requirements
resource "aws_security_group" "ecs_service" {
  count = var.create_service ? 1 : 0

  name_prefix = "${var.cluster_name}-ecs-service-"
  vpc_id      = var.vpc_id
  description = "Security group for ECS service ${var.service_name}"

  # Ingress Rule - Container Port
  # Allows inbound traffic on the container's exposed port
  # Typically used by load balancers to reach the application
  ingress {
    description = "Container port access"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Consider restricting to load balancer security group
  }

  # Egress Rule - All Outbound Traffic
  # Allows containers to make outbound connections
  # Required for pulling images, accessing AWS services, external APIs
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-ecs-service-sg"
    Purpose   = "Security group for ECS service ${var.service_name}"
    ManagedBy = "terraform"
    Module    = "ecs"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# IAM RESOURCES (OPTIONAL)
# ============================================================================
# IAM roles provide secure access to AWS services for ECS tasks
# Execution role: Used by ECS agent for infrastructure operations
# Task role: Used by application code for AWS service access
# ============================================================================

# ECS Task Execution Role
# Used by the ECS agent to pull container images and write logs
# Required for Fargate tasks to function properly
# Should have minimal permissions needed for task execution
resource "aws_iam_role" "ecs_execution" {
  count = var.create_iam_roles ? 1 : 0

  name = var.execution_role_name != null ? var.execution_role_name : "${var.cluster_name}-execution-role"
  path = "/"
  description = "ECS task execution role for ${var.cluster_name}"

  # Trust Policy - ECS Tasks Service
  # Allows ECS tasks service to assume this role
  # Required for ECS agent operations
  assume_role_policy = jsonencode({
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

  tags = merge(var.tags, {
    Name      = var.execution_role_name != null ? var.execution_role_name : "${var.cluster_name}-execution-role"
    Purpose   = "ECS task execution role"
    ManagedBy = "terraform"
    Module    = "ecs"
  })
}

# ECS Execution Role Managed Policy Attachments
# Attaches AWS managed policies required for task execution
# Typically includes AmazonECSTaskExecutionRolePolicy
resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  for_each = var.create_iam_roles ? toset(var.execution_role_managed_policy_arns) : []

  role       = aws_iam_role.ecs_execution[0].name
  policy_arn = each.value
}

# ECS Execution Role Inline Policies
# Custom policies for specific execution requirements
# Used for additional permissions like accessing Parameter Store or Secrets Manager
resource "aws_iam_role_policy" "ecs_execution_inline" {
  for_each = var.create_iam_roles ? var.execution_role_inline_policies : {}

  name   = each.key
  role   = aws_iam_role.ecs_execution[0].id
  policy = each.value
}

# ECS Task Role
# Used by the application code running in containers
# Provides permissions for the application to access AWS services
# Should follow principle of least privilege
resource "aws_iam_role" "ecs_task" {
  count = var.create_iam_roles ? 1 : 0

  name = var.task_role_name != null ? var.task_role_name : "${var.cluster_name}-task-role"
  path = "/"
  description = "ECS task role for application permissions in ${var.cluster_name}"

  # Trust Policy - ECS Tasks Service
  # Allows ECS tasks service to assume this role
  # Required for application code to access AWS services
  assume_role_policy = jsonencode({
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

  tags = merge(var.tags, {
    Name      = var.task_role_name != null ? var.task_role_name : "${var.cluster_name}-task-role"
    Purpose   = "ECS task role for application permissions"
    ManagedBy = "terraform"
    Module    = "ecs"
  })
}

# ECS Task Role Managed Policy Attachments
# Attaches AWS managed policies for application access
# Examples: S3 access, DynamoDB access, etc.
resource "aws_iam_role_policy_attachment" "ecs_task_managed" {
  for_each = var.create_iam_roles ? toset(var.task_role_managed_policy_arns) : []

  role       = aws_iam_role.ecs_task[0].name
  policy_arn = each.value
}

# ECS Task Role Inline Policies
# Custom policies for application-specific AWS service access
# Tailored to the specific needs of the containerized application
resource "aws_iam_role_policy" "ecs_task_inline" {
  for_each = var.create_iam_roles ? var.task_role_inline_policies : {}

  name   = each.key
  role   = aws_iam_role.ecs_task[0].id
  policy = each.value
}