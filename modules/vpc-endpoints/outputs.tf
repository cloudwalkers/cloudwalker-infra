# ============================================================================
# AWS VPC ENDPOINTS MODULE OUTPUTS
# ============================================================================
# Output values for VPC endpoints, security groups, and DNS configurations
# Used for integration with other modules and external references
# ============================================================================

# ============================================================================
# INTERFACE ENDPOINT OUTPUTS
# ============================================================================

output "interface_endpoint_ids" {
  description = "Map of interface endpoint names to their IDs"
  value = {
    for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.id
  }
}

output "interface_endpoint_arns" {
  description = "Map of interface endpoint names to their ARNs"
  value = {
    for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.arn
  }
}

output "interface_endpoint_dns_entries" {
  description = "Map of interface endpoint names to their DNS entries"
  value = {
    for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.dns_entry
  }
}

output "interface_endpoint_network_interface_ids" {
  description = "Map of interface endpoint names to their network interface IDs"
  value = {
    for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.network_interface_ids
  }
}

# ============================================================================
# GATEWAY ENDPOINT OUTPUTS
# ============================================================================

output "gateway_endpoint_ids" {
  description = "Map of gateway endpoint names to their IDs"
  value = {
    for name, endpoint in aws_vpc_endpoint.gateway : name => endpoint.id
  }
}

output "gateway_endpoint_arns" {
  description = "Map of gateway endpoint names to their ARNs"
  value = {
    for name, endpoint in aws_vpc_endpoint.gateway : name => endpoint.arn
  }
}

output "gateway_endpoint_prefix_list_ids" {
  description = "Map of gateway endpoint names to their prefix list IDs"
  value = {
    for name, endpoint in aws_vpc_endpoint.gateway : name => endpoint.prefix_list_id
  }
}

# ============================================================================
# SECURITY GROUP OUTPUTS
# ============================================================================

output "security_group_id" {
  description = "ID of the VPC endpoints security group"
  value       = var.create_security_group ? aws_security_group.vpc_endpoint[0].id : null
}

output "security_group_arn" {
  description = "ARN of the VPC endpoints security group"
  value       = var.create_security_group ? aws_security_group.vpc_endpoint[0].arn : null
}

# ============================================================================
# ALL ENDPOINTS COMBINED
# ============================================================================

output "all_endpoint_ids" {
  description = "Map of all endpoint names to their IDs"
  value = merge(
    {
      for name, endpoint in aws_vpc_endpoint.interface : name => endpoint.id
    },
    {
      for name, endpoint in aws_vpc_endpoint.gateway : name => endpoint.id
    }
  )
}

output "endpoint_summary" {
  description = "Summary of created VPC endpoints"
  value = {
    interface_endpoints = length(aws_vpc_endpoint.interface)
    gateway_endpoints   = length(aws_vpc_endpoint.gateway)
    total_endpoints     = length(aws_vpc_endpoint.interface) + length(aws_vpc_endpoint.gateway)
  }
}