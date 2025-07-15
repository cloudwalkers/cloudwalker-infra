variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.cluster_name))
    error_message = "Cluster name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[1-9]$", var.region))
    error_message = "Region must be a valid AWS region code."
  }
}

variable "container_insights" {
  description = "Enable CloudWatch Container Insights for the cluster"
  type        = bool
  default     = false
}

variable "capacity_providers" {
  description = "List of capacity providers for the cluster"
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy for the cluster"
  type = object({
    base              = number
    weight            = number
    capacity_provider = string
  })
  default = {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_in_days)
    error_message = "Log retention must be a valid CloudWatch retention period."
  }
}

variable "create_service" {
  description = "Whether to create an ECS service"
  type        = bool
  default     = false
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = ""
}

variable "desired_count" {
  description = "Desired number of tasks for the service"
  type        = number
  default     = 1
  validation {
    condition     = var.desired_count >= 0
    error_message = "Desired count must be non-negative."
  }
}

variable "service_capacity_provider" {
  description = "Capacity provider for the service"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["FARGATE", "FARGATE_SPOT", "EC2"], var.service_capacity_provider)
    error_message = "Service capacity provider must be FARGATE, FARGATE_SPOT, or EC2."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the service"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID for security groups"
  type        = string
  default     = ""
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN of the load balancer target group"
  type        = string
  default     = ""
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
  validation {
    condition     = var.container_port > 0 && var.container_port <= 65535
    error_message = "Container port must be between 1 and 65535."
  }
}

variable "task_family" {
  description = "Task definition family name"
  type        = string
  default     = "app"
}

variable "task_cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory (MB) for the task"
  type        = number
  default     = 512
  validation {
    condition     = var.task_memory >= 512 && var.task_memory <= 30720
    error_message = "Task memory must be between 512 and 30720 MB."
  }
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
  default     = "nginx:latest"
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# IAM Configuration
variable "create_iam_roles" {
  description = "Whether to create IAM roles for ECS"
  type        = bool
  default     = false
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role (if not creating)"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN of the ECS task role (if not creating)"
  type        = string
  default     = null
}

variable "execution_role_name" {
  description = "Name for the ECS execution role (if creating)"
  type        = string
  default     = null
}

variable "task_role_name" {
  description = "Name for the ECS task role (if creating)"
  type        = string
  default     = null
}

variable "execution_role_managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the execution role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

variable "task_role_managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the task role"
  type        = list(string)
  default     = []
}

variable "execution_role_inline_policies" {
  description = "Map of inline policies to attach to the execution role"
  type        = map(string)
  default     = {}
}

variable "task_role_inline_policies" {
  description = "Map of inline policies to attach to the task role"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}