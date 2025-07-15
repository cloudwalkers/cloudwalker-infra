# ============================================================================
# AWS ROUTE 53 MODULE OUTPUTS
# ============================================================================
# Output values for Route 53 resources including hosted zones, DNS records,
# health checks, and resolver configurations
# Used for integration with other modules and external references
# ============================================================================

# ============================================================================
# HOSTED ZONE OUTPUTS
# ============================================================================

output "public_hosted_zone_ids" {
  description = "Map of public hosted zone names to their IDs"
  value = {
    for name, zone in aws_route53_zone.public : name => zone.zone_id
  }
}

output "public_hosted_zone_name_servers" {
  description = "Map of public hosted zone names to their name servers"
  value = {
    for name, zone in aws_route53_zone.public : name => zone.name_servers
  }
}

output "private_hosted_zone_ids" {
  description = "Map of private hosted zone names to their IDs"
  value = {
    for name, zone in aws_route53_zone.private : name => zone.zone_id
  }
}

output "private_hosted_zone_name_servers" {
  description = "Map of private hosted zone names to their name servers"
  value = {
    for name, zone in aws_route53_zone.private : name => zone.name_servers
  }
}

output "all_hosted_zone_ids" {
  description = "Map of all hosted zone names to their IDs"
  value = merge(
    {
      for name, zone in aws_route53_zone.public : name => zone.zone_id
    },
    {
      for name, zone in aws_route53_zone.private : name => zone.zone_id
    }
  )
}

# ============================================================================
# DNS RECORD OUTPUTS
# ============================================================================

output "dns_record_names" {
  description = "Map of DNS record keys to their fully qualified domain names"
  value = {
    for name, record in aws_route53_record.simple : name => record.fqdn
  }
}

output "dns_record_types" {
  description = "Map of DNS record keys to their types"
  value = {
    for name, record in aws_route53_record.simple : name => record.type
  }
}

output "dns_record_values" {
  description = "Map of DNS record keys to their values"
  value = {
    for name, record in aws_route53_record.simple : name => record.records
  }
  sensitive = true
}

# ============================================================================
# HEALTH CHECK OUTPUTS
# ============================================================================

output "health_check_ids" {
  description = "Map of health check names to their IDs"
  value = {
    for name, hc in aws_route53_health_check.this : name => hc.id
  }
}

output "health_check_arns" {
  description = "Map of health check names to their ARNs"
  value = {
    for name, hc in aws_route53_health_check.this : name => hc.arn
  }
}

output "health_check_cloudwatch_alarm_names" {
  description = "Map of health check names to their CloudWatch alarm names"
  value = {
    for name, hc in aws_route53_health_check.this : name => hc.cloudwatch_alarm_name
  }
}

# ============================================================================
# RESOLVER OUTPUTS
# ============================================================================

output "resolver_rule_ids" {
  description = "Map of resolver rule names to their IDs"
  value = {
    for name, rule in aws_route53_resolver_rule.this : name => rule.id
  }
}

output "resolver_rule_arns" {
  description = "Map of resolver rule names to their ARNs"
  value = {
    for name, rule in aws_route53_resolver_rule.this : name => rule.arn
  }
}

output "resolver_endpoint_ids" {
  description = "Map of resolver endpoint names to their IDs"
  value = merge(
    {
      for name, endpoint in aws_route53_resolver_endpoint.inbound : "${name}-inbound" => endpoint.id
    },
    {
      for name, endpoint in aws_route53_resolver_endpoint.outbound : "${name}-outbound" => endpoint.id
    }
  )
}

output "resolver_endpoint_ips" {
  description = "Map of resolver endpoint names to their IP addresses"
  value = merge(
    {
      for name, endpoint in aws_route53_resolver_endpoint.inbound : "${name}-inbound" => [
        for ip in endpoint.ip_address : ip.ip
      ]
    },
    {
      for name, endpoint in aws_route53_resolver_endpoint.outbound : "${name}-outbound" => [
        for ip in endpoint.ip_address : ip.ip
      ]
    }
  )
}

# ============================================================================
# DELEGATION SET OUTPUTS
# ============================================================================

output "delegation_set_ids" {
  description = "Map of delegation set names to their IDs"
  value = {
    for name, ds in aws_route53_delegation_set.this : name => ds.id
  }
}

output "delegation_set_name_servers" {
  description = "Map of delegation set names to their name servers"
  value = {
    for name, ds in aws_route53_delegation_set.this : name => ds.name_servers
  }
}

# ============================================================================
# QUERY LOGGING OUTPUTS
# ============================================================================

output "query_log_config_ids" {
  description = "Map of query logging config names to their IDs"
  value = {
    for name, log in aws_route53_query_log.this : name => log.id
  }
}

output "query_log_cloudwatch_log_group_arns" {
  description = "Map of query logging config names to their CloudWatch Log Group ARNs"
  value = {
    for name, log_group in aws_cloudwatch_log_group.route53_query_log : name => log_group.arn
  }
}

# ============================================================================
# TRAFFIC POLICY OUTPUTS
# ============================================================================

output "traffic_policy_ids" {
  description = "Map of traffic policy names to their IDs"
  value = {
    for name, policy in aws_route53_traffic_policy.this : name => policy.id
  }
}

output "traffic_policy_versions" {
  description = "Map of traffic policy names to their versions"
  value = {
    for name, policy in aws_route53_traffic_policy.this : name => policy.version
  }
}

output "traffic_policy_instance_ids" {
  description = "Map of traffic policy instance names to their IDs"
  value = {
    for name, instance in aws_route53_traffic_policy_instance.this : name => instance.id
  }
}

# ============================================================================
# ZONE ASSOCIATION OUTPUTS
# ============================================================================

output "vpc_association_ids" {
  description = "Map of VPC association names to their IDs"
  value = {
    for name, assoc in aws_route53_zone_association.additional : name => assoc.id
  }
}

# ============================================================================
# COMPREHENSIVE SUMMARY OUTPUTS
# ============================================================================

output "route53_summary" {
  description = "Summary of all Route 53 resources created"
  value = {
    hosted_zones = {
      public_zones  = length(aws_route53_zone.public)
      private_zones = length(aws_route53_zone.private)
      total_zones   = length(aws_route53_zone.public) + length(aws_route53_zone.private)
    }
    dns_records = {
      total_records = length(aws_route53_record.simple)
      record_types = {
        for type in distinct([for record in aws_route53_record.simple : record.type]) :
        type => length([for record in aws_route53_record.simple : record if record.type == type])
      }
    }
    health_checks = {
      total_health_checks = length(aws_route53_health_check.this)
      health_check_types = {
        for type in distinct([for hc in aws_route53_health_check.this : hc.type]) :
        type => length([for hc in aws_route53_health_check.this : hc if hc.type == type])
      }
    }
    resolver = {
      resolver_rules     = length(aws_route53_resolver_rule.this)
      inbound_endpoints  = length(aws_route53_resolver_endpoint.inbound)
      outbound_endpoints = length(aws_route53_resolver_endpoint.outbound)
    }
    traffic_policies = {
      policies  = length(aws_route53_traffic_policy.this)
      instances = length(aws_route53_traffic_policy_instance.this)
    }
  }
}

# ============================================================================
# DOMAIN CONFIGURATION OUTPUTS
# ============================================================================

output "domain_configurations" {
  description = "Complete domain configuration details"
  value = {
    for zone_name, zone in merge(aws_route53_zone.public, aws_route53_zone.private) : zone_name => {
      zone_id      = zone.zone_id
      domain_name  = zone.name
      name_servers = zone.name_servers
      zone_type    = contains(keys(aws_route53_zone.public), zone_name) ? "public" : "private"
      records = {
        for record_name, record in aws_route53_record.simple :
        record_name => {
          name = record.name
          type = record.type
          ttl  = record.ttl
          fqdn = record.fqdn
        } if record.zone_id == zone.zone_id
      }
    }
  }
}

# ============================================================================
# INTEGRATION OUTPUTS
# ============================================================================

output "name_servers_for_domain_registration" {
  description = "Name servers to use for domain registration (public zones only)"
  value = {
    for name, zone in aws_route53_zone.public : zone.name => zone.name_servers
  }
}

output "resolver_rule_associations" {
  description = "Map of resolver rule association names to their details"
  value = {
    for name, assoc in aws_route53_resolver_rule_association.this : name => {
      id               = assoc.id
      resolver_rule_id = assoc.resolver_rule_id
      vpc_id           = assoc.vpc_id
    }
  }
}

# ============================================================================
# MONITORING AND LOGGING OUTPUTS
# ============================================================================

output "cloudwatch_log_groups" {
  description = "CloudWatch Log Groups created for query logging"
  value = {
    for name, log_group in aws_cloudwatch_log_group.route53_query_log : name => {
      name              = log_group.name
      arn               = log_group.arn
      retention_in_days = log_group.retention_in_days
    }
  }
}

output "health_check_monitoring" {
  description = "Health check monitoring configuration"
  value = {
    for name, hc in aws_route53_health_check.this : name => {
      id                    = hc.id
      cloudwatch_alarm_name = hc.cloudwatch_alarm_name
      measure_latency       = hc.measure_latency
      type                  = hc.type
      fqdn                  = hc.fqdn
      ip_address            = hc.ip_address
    }
  }
}