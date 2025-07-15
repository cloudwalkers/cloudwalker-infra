# ============================================================================
# AWS VPC ENDPOINTS MODULE VARIABLES
# ============================================================================
# Variable definitions for VPC endpoint configuration
# Supports both Gateway and Interface endpoint types
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "name_prefix" {
  description = "Prefix for naming VPC endpoint resources"
  type        = string
  default     = "vpc-endpoints"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all VPC endpoint resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# VPC CONFIGURATION
# ============================================================================

variable "vpc_id" {
  description = "ID of the VPC where endpoints will be created"
  type        = string
}

variable "route_table_ids" {
  description = "List of route table IDs for gateway endpoints (auto-detected if empty)"
  type        = list(string)
  default     = []
}

variable "auto_accept" {
  description = "Automatically accept and associate with private route tables"
  type        = bool
  default     = true
}

# ============================================================================
# ENDPOINT CONFIGURATION
# ============================================================================

variable "endpoints" {
  description = "Map of VPC endpoints to create"
  type = map(object({
    service_name        = string
    vpc_endpoint_type   = string
    subnet_ids          = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    route_table_ids     = optional(list(string), [])
    policy              = optional(string)
    private_dns_enabled = optional(bool, true)
    tags                = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.endpoints : contains(["Interface", "Gateway"], config.vpc_endpoint_type)
    ])
    error_message = "VPC endpoint type must be either 'Interface' or 'Gateway'."
  }

  validation {
    condition = alltrue([
      for name, config in var.endpoints : 
      config.vpc_endpoint_type == "Gateway" || length(config.subnet_ids) > 0
    ])
    error_message = "Interface endpoints must specify subnet_ids."
  }
}

# ============================================================================
# SECURITY GROUP CONFIGURATION
# ============================================================================

variable "create_security_group" {
  description = "Whether to create a default security group for interface endpoints"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access VPC endpoints"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "allow_http" {
  description = "Allow HTTP traffic (port 80) in addition to HTTPS (port 443)"
  type        = bool
  default     = false
}

# ============================================================================
# DNS RESOLVER CONFIGURATION
# ============================================================================

variable "create_resolver_rules" {
  description = "Whether to create Route 53 resolver rules for custom DNS resolution"
  type        = bool
  default     = false
}

variable "resolver_rules" {
  description = "Map of Route 53 resolver rules for custom DNS resolution"
  type = map(object({
    domain_name          = string
    rule_type            = string
    resolver_endpoint_id = optional(string)
    target_ips = optional(list(object({
      ip   = string
      port = optional(number, 53)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, rule in var.resolver_rules : contains(["FORWARD", "SYSTEM", "RECURSIVE"], rule.rule_type)
    ])
    error_message = "Resolver rule type must be one of: FORWARD, SYSTEM, RECURSIVE."
  }
}

# ============================================================================
# MONITORING CONFIGURATION
# ============================================================================

variable "enable_endpoint_monitoring" {
  description = "Enable CloudWatch Events monitoring for VPC endpoint state changes"
  type        = bool
  default     = false
}

variable "monitoring_sns_topic_arn" {
  description = "SNS topic ARN for VPC endpoint monitoring notifications"
  type        = string
  default     = null
}

# ============================================================================
# COMMON ENDPOINT CONFIGURATIONS
# ============================================================================
# Pre-defined configurations for common AWS services

variable "enable_s3_endpoint" {
  description = "Enable S3 gateway endpoint"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB gateway endpoint"
  type        = bool
  default     = false
}

variable "enable_ec2_endpoint" {
  description = "Enable EC2 interface endpoint"
  type        = bool
  default     = false
}

variable "enable_ssm_endpoints" {
  description = "Enable SSM-related interface endpoints (SSM, SSMMessages, EC2Messages)"
  type        = bool
  default     = false
}

variable "enable_logs_endpoint" {
  description = "Enable CloudWatch Logs interface endpoint"
  type        = bool
  default     = false
}

variable "enable_monitoring_endpoint" {
  description = "Enable CloudWatch Monitoring interface endpoint"
  type        = bool
  default     = false
}

variable "enable_ecr_endpoints" {
  description = "Enable ECR interface endpoints (ECR API and ECR DKR)"
  type        = bool
  default     = false
}

variable "enable_ecs_endpoints" {
  description = "Enable ECS-related interface endpoints (ECS Agent, ECS Telemetry)"
  type        = bool
  default     = false
}

variable "enable_lambda_endpoint" {
  description = "Enable Lambda interface endpoint"
  type        = bool
  default     = false
}

variable "enable_secrets_manager_endpoint" {
  description = "Enable Secrets Manager interface endpoint"
  type        = bool
  default     = false
}

variable "enable_kms_endpoint" {
  description = "Enable KMS interface endpoint"
  type        = bool
  default     = false
}

variable "enable_sns_endpoint" {
  description = "Enable SNS interface endpoint"
  type        = bool
  default     = false
}

variable "enable_sqs_endpoint" {
  description = "Enable SQS interface endpoint"
  type        = bool
  default     = false
}

# ============================================================================
# INTERFACE ENDPOINT CONFIGURATION
# ============================================================================

variable "interface_endpoint_subnet_ids" {
  description = "Subnet IDs for interface endpoints (used with enable_* variables)"
  type        = list(string)
  default     = []
}

variable "interface_endpoint_security_group_ids" {
  description = "Security group IDs for interface endpoints (uses default if empty)"
  type        = list(string)
  default     = []
}