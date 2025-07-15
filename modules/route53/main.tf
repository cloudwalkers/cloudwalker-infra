# ============================================================================
# AWS ROUTE 53 MODULE
# ============================================================================
# This module creates and manages AWS Route 53 resources for DNS management
# including hosted zones, DNS records, health checks, and resolver rules.
# Route 53 provides:
# - Scalable and highly available DNS service
# - Domain registration and management
# - Health checking and DNS failover
# - Private DNS for VPC resources
# - Traffic routing policies (weighted, latency-based, geolocation)
# - Integration with other AWS services
# ============================================================================

# ============================================================================
# DATA SOURCES
# ============================================================================
# Retrieve information about existing hosted zones and domains

data "aws_route53_zone" "existing" {
  for_each = var.use_existing_hosted_zones

  name         = each.value.name
  private_zone = each.value.private_zone
  vpc_id       = each.value.vpc_id
}

# ============================================================================
# HOSTED ZONES
# ============================================================================
# DNS hosted zones for domain management
# Supports both public and private hosted zones
# Provides authoritative DNS responses for domains
resource "aws_route53_zone" "public" {
  for_each = var.create_hosted_zones ? var.public_hosted_zones : {}

  name              = each.value.domain_name
  comment           = each.value.comment
  delegation_set_id = each.value.delegation_set_id
  force_destroy     = each.value.force_destroy

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = each.value.domain_name
      Environment = var.environment
      Module      = "route53"
      Type        = "public-hosted-zone"
    }
  )
}

resource "aws_route53_zone" "private" {
  for_each = var.create_hosted_zones ? var.private_hosted_zones : {}

  name    = each.value.domain_name
  comment = each.value.comment

  # VPC associations for private hosted zones
  dynamic "vpc" {
    for_each = each.value.vpc_associations
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  force_destroy = each.value.force_destroy

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = each.value.domain_name
      Environment = var.environment
      Module      = "route53"
      Type        = "private-hosted-zone"
    }
  )
}

# ============================================================================
# VPC ASSOCIATIONS FOR EXISTING PRIVATE ZONES
# ============================================================================
# Associate additional VPCs with existing private hosted zones
# Enables cross-VPC DNS resolution
resource "aws_route53_zone_association" "additional" {
  for_each = var.additional_vpc_associations

  zone_id    = each.value.zone_id
  vpc_id     = each.value.vpc_id
  vpc_region = each.value.vpc_region
}

# ============================================================================
# DNS RECORDS
# ============================================================================
# DNS records for various resource types and routing policies
# Supports A, AAAA, CNAME, MX, TXT, SRV, PTR, and other record types

# Simple DNS records
resource "aws_route53_record" "simple" {
  for_each = var.dns_records

  zone_id = each.value.zone_id != null ? each.value.zone_id : (
    each.value.zone_name != null ? (
      contains(keys(aws_route53_zone.public), each.value.zone_name) ? aws_route53_zone.public[each.value.zone_name].zone_id :
      contains(keys(aws_route53_zone.private), each.value.zone_name) ? aws_route53_zone.private[each.value.zone_name].zone_id :
      data.aws_route53_zone.existing[each.value.zone_name].zone_id
    ) : null
  )

  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.alias == null ? each.value.ttl : null
  records = each.value.alias == null ? each.value.records : null

  # Alias configuration for AWS resources
  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  # Weighted routing policy
  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing_policy != null ? [each.value.weighted_routing_policy] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  # Latency-based routing policy
  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing_policy != null ? [each.value.latency_routing_policy] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  # Geolocation routing policy
  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation_routing_policy != null ? [each.value.geolocation_routing_policy] : []
    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  # Failover routing policy
  dynamic "failover_routing_policy" {
    for_each = each.value.failover_routing_policy != null ? [each.value.failover_routing_policy] : []
    content {
      type = failover_routing_policy.value.type
    }
  }

  # Multivalue answer routing policy
  dynamic "multivalue_answer_routing_policy" {
    for_each = each.value.multivalue_answer_routing_policy != null ? [each.value.multivalue_answer_routing_policy] : []
    content {}
  }

  # Health check association
  health_check_id = each.value.health_check_id
  set_identifier  = each.value.set_identifier

  # Lifecycle management
  allow_overwrite = each.value.allow_overwrite
}

# ============================================================================
# HEALTH CHECKS
# ============================================================================
# Health checks for DNS failover and monitoring
# Supports HTTP, HTTPS, TCP, and calculated health checks
resource "aws_route53_health_check" "this" {
  for_each = var.health_checks

  type                            = each.value.type
  resource_path                   = each.value.resource_path
  fqdn                           = each.value.fqdn
  ip_address                     = each.value.ip_address
  port                           = each.value.port
  request_interval               = each.value.request_interval
  failure_threshold              = each.value.failure_threshold
  measure_latency                = each.value.measure_latency
  invert_healthcheck             = each.value.invert_healthcheck
  disabled                       = each.value.disabled
  enable_sni                     = each.value.enable_sni
  search_string                  = each.value.search_string
  cloudwatch_logs_region         = each.value.cloudwatch_logs_region
  cloudwatch_logs_group_name     = each.value.cloudwatch_logs_group_name
  insufficient_data_health_status = each.value.insufficient_data_health_status

  # Child health checks for calculated health checks
  dynamic "child_health_checks" {
    for_each = each.value.child_health_checks != null ? [each.value.child_health_checks] : []
    content {
      child_health_checks                 = child_health_checks.value.child_health_checks
      child_health_threshold              = child_health_checks.value.child_health_threshold
      cloudwatch_alarm_region             = child_health_checks.value.cloudwatch_alarm_region
      cloudwatch_alarm_name               = child_health_checks.value.cloudwatch_alarm_name
      insufficient_data_health_status     = child_health_checks.value.insufficient_data_health_status
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = each.key
      Environment = var.environment
      Module      = "route53"
      Type        = "health-check"
    }
  )
}

# ============================================================================
# RESOLVER RULES
# ============================================================================
# Route 53 Resolver rules for DNS forwarding
# Enables custom DNS resolution for hybrid environments
resource "aws_route53_resolver_rule" "this" {
  for_each = var.resolver_rules

  domain_name          = each.value.domain_name
  name                 = each.value.name
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.resolver_endpoint_id

  # Target IP addresses for FORWARD rules
  dynamic "target_ip" {
    for_each = each.value.target_ips
    content {
      ip   = target_ip.value.ip
      port = target_ip.value.port
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = each.value.name
      Environment = var.environment
      Module      = "route53"
      Type        = "resolver-rule"
    }
  )
}

# ============================================================================
# RESOLVER RULE ASSOCIATIONS
# ============================================================================
# Associate resolver rules with VPCs
# Enables custom DNS resolution within VPCs
resource "aws_route53_resolver_rule_association" "this" {
  for_each = var.resolver_rule_associations

  resolver_rule_id = each.value.resolver_rule_id != null ? each.value.resolver_rule_id : aws_route53_resolver_rule.this[each.value.resolver_rule_name].id
  vpc_id           = each.value.vpc_id
}

# ============================================================================
# RESOLVER ENDPOINTS
# ============================================================================
# Route 53 Resolver endpoints for hybrid DNS resolution
# Enables DNS queries between VPC and on-premises networks
resource "aws_route53_resolver_endpoint" "inbound" {
  for_each = var.resolver_endpoints.inbound

  name      = each.value.name
  direction = "INBOUND"

  security_group_ids = each.value.security_group_ids

  dynamic "ip_address" {
    for_each = each.value.ip_addresses
    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = each.value.name
      Environment = var.environment
      Module      = "route53"
      Type        = "inbound-resolver-endpoint"
    }
  )
}

resource "aws_route53_resolver_endpoint" "outbound" {
  for_each = var.resolver_endpoints.outbound

  name      = each.value.name
  direction = "OUTBOUND"

  security_group_ids = each.value.security_group_ids

  dynamic "ip_address" {
    for_each = each.value.ip_addresses
    content {
      subnet_id = ip_address.value.subnet_id
      ip        = ip_address.value.ip
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = each.value.name
      Environment = var.environment
      Module      = "route53"
      Type        = "outbound-resolver-endpoint"
    }
  )
}

# ============================================================================
# DELEGATION SETS
# ============================================================================
# Reusable delegation sets for consistent name servers
# Useful for multiple domains with same name servers
resource "aws_route53_delegation_set" "this" {
  for_each = var.delegation_sets

  reference_name = each.value.reference_name
}

# ============================================================================
# QUERY LOGGING CONFIGURATION
# ============================================================================
# DNS query logging for monitoring and analysis
# Logs DNS queries to CloudWatch Logs
resource "aws_route53_query_log" "this" {
  for_each = var.query_logging_configs

  depends_on = [aws_cloudwatch_log_group.route53_query_log]

  destination_arn = aws_cloudwatch_log_group.route53_query_log[each.key].arn
  zone_id = each.value.zone_id != null ? each.value.zone_id : (
    each.value.zone_name != null ? (
      contains(keys(aws_route53_zone.public), each.value.zone_name) ? aws_route53_zone.public[each.value.zone_name].zone_id :
      contains(keys(aws_route53_zone.private), each.value.zone_name) ? aws_route53_zone.private[each.value.zone_name].zone_id :
      data.aws_route53_zone.existing[each.value.zone_name].zone_id
    ) : null
  )
}

# ============================================================================
# CLOUDWATCH LOG GROUPS FOR QUERY LOGGING
# ============================================================================
# CloudWatch Log Groups for Route 53 query logs
# Stores DNS query logs for analysis and monitoring
resource "aws_cloudwatch_log_group" "route53_query_log" {
  for_each = var.query_logging_configs

  name              = "/aws/route53/${each.key}"
  retention_in_days = each.value.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "/aws/route53/${each.key}"
      Environment = var.environment
      Module      = "route53"
      Type        = "query-log-group"
    }
  )
}

# ============================================================================
# TRAFFIC POLICY
# ============================================================================
# Route 53 traffic policies for advanced routing
# Supports complex routing logic with multiple conditions
resource "aws_route53_traffic_policy" "this" {
  for_each = var.traffic_policies

  name     = each.value.name
  comment  = each.value.comment
  document = each.value.document
}

# ============================================================================
# TRAFFIC POLICY INSTANCES
# ============================================================================
# Instances of traffic policies applied to specific domains
# Links traffic policies to hosted zones and domain names
resource "aws_route53_traffic_policy_instance" "this" {
  for_each = var.traffic_policy_instances

  name                   = each.value.name
  traffic_policy_id      = aws_route53_traffic_policy.this[each.value.traffic_policy_name].id
  traffic_policy_version = each.value.traffic_policy_version
  hosted_zone_id = each.value.hosted_zone_id != null ? each.value.hosted_zone_id : (
    each.value.hosted_zone_name != null ? (
      contains(keys(aws_route53_zone.public), each.value.hosted_zone_name) ? aws_route53_zone.public[each.value.hosted_zone_name].zone_id :
      contains(keys(aws_route53_zone.private), each.value.hosted_zone_name) ? aws_route53_zone.private[each.value.hosted_zone_name].zone_id :
      data.aws_route53_zone.existing[each.value.hosted_zone_name].zone_id
    ) : null
  )
  ttl = each.value.ttl
}