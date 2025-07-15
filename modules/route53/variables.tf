# ============================================================================
# AWS ROUTE 53 MODULE VARIABLES
# ============================================================================
# Variable definitions for Route 53 DNS management
# Supports hosted zones, DNS records, health checks, and resolver configuration
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all Route 53 resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# HOSTED ZONES CONFIGURATION
# ============================================================================

variable "create_hosted_zones" {
  description = "Whether to create new hosted zones"
  type        = bool
  default     = true
}

variable "use_existing_hosted_zones" {
  description = "Map of existing hosted zones to reference"
  type = map(object({
    name         = string
    private_zone = optional(bool, false)
    vpc_id       = optional(string)
  }))
  default = {}
}

variable "public_hosted_zones" {
  description = "Map of public hosted zones to create"
  type = map(object({
    domain_name       = string
    comment           = optional(string, "Managed by Terraform")
    delegation_set_id = optional(string)
    force_destroy     = optional(bool, false)
    tags              = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, zone in var.public_hosted_zones : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\\.[a-zA-Z]{2,}$", zone.domain_name))
    ])
    error_message = "Domain names must be valid DNS names."
  }
}

variable "private_hosted_zones" {
  description = "Map of private hosted zones to create"
  type = map(object({
    domain_name = string
    comment     = optional(string, "Private zone managed by Terraform")
    vpc_associations = list(object({
      vpc_id     = string
      vpc_region = optional(string)
    }))
    force_destroy = optional(bool, false)
    tags          = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, zone in var.private_hosted_zones : can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]*\\.[a-zA-Z]{2,}$", zone.domain_name))
    ])
    error_message = "Domain names must be valid DNS names."
  }
}

variable "additional_vpc_associations" {
  description = "Additional VPC associations for existing private hosted zones"
  type = map(object({
    zone_id    = string
    vpc_id     = string
    vpc_region = optional(string)
  }))
  default = {}
}

# ============================================================================
# DNS RECORDS CONFIGURATION
# ============================================================================

variable "dns_records" {
  description = "Map of DNS records to create"
  type = map(object({
    zone_id    = optional(string)
    zone_name  = optional(string)
    name       = string
    type       = string
    ttl        = optional(number, 300)
    records    = optional(list(string))
    
    # Alias configuration for AWS resources
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, false)
    }))
    
    # Routing policies
    weighted_routing_policy = optional(object({
      weight = number
    }))
    
    latency_routing_policy = optional(object({
      region = string
    }))
    
    geolocation_routing_policy = optional(object({
      continent   = optional(string)
      country     = optional(string)
      subdivision = optional(string)
    }))
    
    failover_routing_policy = optional(object({
      type = string
    }))
    
    multivalue_answer_routing_policy = optional(object({}))
    
    # Health check and routing
    health_check_id = optional(string)
    set_identifier  = optional(string)
    allow_overwrite = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, record in var.dns_records : contains([
        "A", "AAAA", "CNAME", "MX", "NS", "PTR", "SOA", "SPF", "SRV", "TXT"
      ], record.type)
    ])
    error_message = "DNS record type must be one of: A, AAAA, CNAME, MX, NS, PTR, SOA, SPF, SRV, TXT."
  }

  validation {
    condition = alltrue([
      for name, record in var.dns_records : record.alias != null || record.records != null
    ])
    error_message = "DNS record must have either 'alias' or 'records' specified."
  }

  validation {
    condition = alltrue([
      for name, record in var.dns_records : 
      record.failover_routing_policy == null || contains(["PRIMARY", "SECONDARY"], record.failover_routing_policy.type)
    ])
    error_message = "Failover routing policy type must be either 'PRIMARY' or 'SECONDARY'."
  }
}

# ============================================================================
# HEALTH CHECKS CONFIGURATION
# ============================================================================

variable "health_checks" {
  description = "Map of health checks to create"
  type = map(object({
    type                            = string
    resource_path                   = optional(string, "/")
    fqdn                           = optional(string)
    ip_address                     = optional(string)
    port                           = optional(number, 80)
    request_interval               = optional(number, 30)
    failure_threshold              = optional(number, 3)
    measure_latency                = optional(bool, false)
    invert_healthcheck             = optional(bool, false)
    disabled                       = optional(bool, false)
    enable_sni                     = optional(bool, true)
    search_string                  = optional(string)
    cloudwatch_logs_region         = optional(string)
    cloudwatch_logs_group_name     = optional(string)
    insufficient_data_health_status = optional(string, "Failure")
    
    # For calculated health checks
    child_health_checks = optional(object({
      child_health_checks                 = list(string)
      child_health_threshold              = optional(number)
      cloudwatch_alarm_region             = optional(string)
      cloudwatch_alarm_name               = optional(string)
      insufficient_data_health_status     = optional(string, "Failure")
    }))
    
    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, hc in var.health_checks : contains([
        "HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH", "TCP", "CALCULATED", "CLOUDWATCH_METRIC"
      ], hc.type)
    ])
    error_message = "Health check type must be one of: HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP, CALCULATED, CLOUDWATCH_METRIC."
  }

  validation {
    condition = alltrue([
      for name, hc in var.health_checks : hc.request_interval == 10 || hc.request_interval == 30
    ])
    error_message = "Health check request interval must be either 10 or 30 seconds."
  }

  validation {
    condition = alltrue([
      for name, hc in var.health_checks : hc.failure_threshold >= 1 && hc.failure_threshold <= 10
    ])
    error_message = "Health check failure threshold must be between 1 and 10."
  }
}

# ============================================================================
# RESOLVER CONFIGURATION
# ============================================================================

variable "resolver_rules" {
  description = "Map of Route 53 Resolver rules to create"
  type = map(object({
    domain_name          = string
    name                 = string
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

variable "resolver_rule_associations" {
  description = "Map of resolver rule associations with VPCs"
  type = map(object({
    resolver_rule_id   = optional(string)
    resolver_rule_name = optional(string)
    vpc_id             = string
  }))
  default = {}
}

variable "resolver_endpoints" {
  description = "Resolver endpoints configuration"
  type = object({
    inbound = optional(map(object({
      name               = string
      security_group_ids = list(string)
      ip_addresses = list(object({
        subnet_id = string
        ip        = optional(string)
      }))
      tags = optional(map(string), {})
    })), {})
    
    outbound = optional(map(object({
      name               = string
      security_group_ids = list(string)
      ip_addresses = list(object({
        subnet_id = string
        ip        = optional(string)
      }))
      tags = optional(map(string), {})
    })), {})
  })
  default = {
    inbound  = {}
    outbound = {}
  }
}

# ============================================================================
# DELEGATION SETS CONFIGURATION
# ============================================================================

variable "delegation_sets" {
  description = "Map of delegation sets to create"
  type = map(object({
    reference_name = optional(string)
  }))
  default = {}
}

# ============================================================================
# QUERY LOGGING CONFIGURATION
# ============================================================================

variable "query_logging_configs" {
  description = "Map of query logging configurations"
  type = map(object({
    zone_id             = optional(string)
    zone_name           = optional(string)
    log_retention_days  = optional(number, 30)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, config in var.query_logging_configs : config.log_retention_days >= 1 && config.log_retention_days <= 3653
    ])
    error_message = "Log retention days must be between 1 and 3653."
  }
}

# ============================================================================
# TRAFFIC POLICY CONFIGURATION
# ============================================================================

variable "traffic_policies" {
  description = "Map of traffic policies to create"
  type = map(object({
    name     = string
    comment  = optional(string)
    document = string
  }))
  default = {}
}

variable "traffic_policy_instances" {
  description = "Map of traffic policy instances to create"
  type = map(object({
    name                   = string
    traffic_policy_name    = string
    traffic_policy_version = number
    hosted_zone_id         = optional(string)
    hosted_zone_name       = optional(string)
    ttl                    = number
  }))
  default = {}
}