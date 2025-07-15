variable "name" {
  description = "Name of the load balancer"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name)) && length(var.name) <= 32
    error_message = "Load balancer name must contain only alphanumeric characters and hyphens, and be 32 characters or less."
  }
}

variable "internal" {
  description = "Whether the load balancer is internal or internet-facing"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "Type of load balancer to create. Valid values: application, gateway, network"
  type        = string
  default     = "application"
  validation {
    condition     = contains(["application", "gateway", "network"], var.load_balancer_type)
    error_message = "Load balancer type must be one of: application, gateway, network."
  }
}

variable "vpc_id" {
  description = "VPC ID where the load balancer will be created"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8}([a-f0-9]{9})?$", var.vpc_id))
    error_message = "VPC ID must be a valid VPC ID format."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs to attach to the load balancer"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets are required for load balancer high availability."
  }
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the load balancer"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for the load balancer"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enable HTTP/2 for application load balancers"
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Connection idle timeout in seconds"
  type        = number
  default     = 60
  validation {
    condition     = var.idle_timeout >= 1 && var.idle_timeout <= 4000
    error_message = "Idle timeout must be between 1 and 4000 seconds."
  }
}

variable "ip_address_type" {
  description = "IP address type for the load balancer. Valid values: ipv4, dualstack"
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "IP address type must be either ipv4 or dualstack."
  }
}

variable "access_logs_enabled" {
  description = "Enable access logs for the load balancer"
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for access logs"
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 prefix for access logs"
  type        = string
  default     = ""
}

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    port                         = number
    protocol                     = string
    target_type                  = optional(string, "instance")
    deregistration_delay         = optional(number, 300)
    slow_start                   = optional(number, 0)
    load_balancing_algorithm_type = optional(string, "round_robin")
    preserve_client_ip           = optional(string, null)
    protocol_version             = optional(string, "HTTP1")
    health_check = optional(object({
      enabled             = optional(bool, true)
      healthy_threshold   = optional(number, 3)
      unhealthy_threshold = optional(number, 3)
      timeout             = optional(number, 5)
      interval            = optional(number, 30)
      path                = optional(string, "/")
      matcher             = optional(string, "200")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
    }))
    stickiness = optional(object({
      type            = string
      cookie_duration = optional(number, 86400)
      cookie_name     = optional(string, null)
      enabled         = optional(bool, true)
    }))
  }))
  default = {}
}

variable "listener_rules" {
  description = "Map of listener configurations"
  type = map(object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string, "ELBSecurityPolicy-TLS-1-2-2017-01")
    certificate_arn = optional(string, null)
    default_action = object({
      type               = string
      target_group_name  = optional(string, null)
      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
        host        = optional(string, "#{host}")
        path        = optional(string, "/#{path}")
        query       = optional(string, "#{query}")
      }))
      fixed_response = optional(object({
        content_type = string
        message_body = optional(string, "")
        status_code  = string
      }))
    })
  }))
  default = {}
}

variable "listener_rules_additional" {
  description = "Additional listener rules for path-based or host-based routing"
  type = map(object({
    listener_key = string
    priority     = number
    action = object({
      type               = string
      target_group_name  = optional(string, null)
      redirect = optional(object({
        port        = optional(string, "443")
        protocol    = optional(string, "HTTPS")
        status_code = optional(string, "HTTP_301")
        host        = optional(string, "#{host}")
        path        = optional(string, "/#{path}")
        query       = optional(string, "#{query}")
      }))
      fixed_response = optional(object({
        content_type = string
        message_body = optional(string, "")
        status_code  = string
      }))
    })
    conditions = list(object({
      field             = string
      values            = optional(list(string), [])
      http_header_name  = optional(string, null)
      query_string = optional(list(object({
        key   = optional(string, null)
        value = string
      })), [])
    }))
  }))
  default = {}
}

variable "target_group_attachments" {
  description = "Map of target group attachments"
  type = map(object({
    target_group_name = string
    target_id         = string
    port              = optional(number, null)
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}