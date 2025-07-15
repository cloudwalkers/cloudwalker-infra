# ============================================================================
# AWS VPC TRANSIT GATEWAY MODULE OUTPUTS
# ============================================================================
# Output values for Transit Gateway, attachments, and routing configurations
# Used for integration with other modules and external references
# ============================================================================

# ============================================================================
# TRANSIT GATEWAY OUTPUTS
# ============================================================================

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].id : null
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].arn : null
}

output "transit_gateway_owner_id" {
  description = "Owner ID of the Transit Gateway"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].owner_id : null
}

output "transit_gateway_association_default_route_table_id" {
  description = "ID of the default association route table"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].association_default_route_table_id : null
}

output "transit_gateway_propagation_default_route_table_id" {
  description = "ID of the default propagation route table"
  value       = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].propagation_default_route_table_id : null
}

# ============================================================================
# VPC ATTACHMENT OUTPUTS
# ============================================================================

output "vpc_attachment_ids" {
  description = "Map of VPC attachment names to their IDs"
  value = {
    for name, attachment in aws_ec2_transit_gateway_vpc_attachment.this : name => attachment.id
  }
}

output "vpc_attachment_arns" {
  description = "Map of VPC attachment names to their ARNs"
  value = {
    for name, attachment in aws_ec2_transit_gateway_vpc_attachment.this : name => attachment.arn
  }
}

output "vpc_attachment_vpc_owner_ids" {
  description = "Map of VPC attachment names to their VPC owner IDs"
  value = {
    for name, attachment in aws_ec2_transit_gateway_vpc_attachment.this : name => attachment.vpc_owner_id
  }
}

# ============================================================================
# ROUTE TABLE OUTPUTS
# ============================================================================

output "route_table_ids" {
  description = "Map of route table names to their IDs"
  value = {
    for name, rt in aws_ec2_transit_gateway_route_table.this : name => rt.id
  }
}

output "route_table_arns" {
  description = "Map of route table names to their ARNs"
  value = {
    for name, rt in aws_ec2_transit_gateway_route_table.this : name => rt.arn
  }
}

output "route_table_default_association_route_table" {
  description = "Map of route table names to their default association status"
  value = {
    for name, rt in aws_ec2_transit_gateway_route_table.this : name => rt.default_association_route_table
  }
}

output "route_table_default_propagation_route_table" {
  description = "Map of route table names to their default propagation status"
  value = {
    for name, rt in aws_ec2_transit_gateway_route_table.this : name => rt.default_propagation_route_table
  }
}

# ============================================================================
# ROUTE TABLE ASSOCIATION OUTPUTS
# ============================================================================

output "route_table_association_ids" {
  description = "Map of route table association names to their IDs"
  value = {
    for name, association in aws_ec2_transit_gateway_route_table_association.this : name => association.id
  }
}

output "route_table_association_resource_ids" {
  description = "Map of route table association names to their resource IDs"
  value = {
    for name, association in aws_ec2_transit_gateway_route_table_association.this : name => association.resource_id
  }
}

# ============================================================================
# ROUTE TABLE PROPAGATION OUTPUTS
# ============================================================================

output "route_table_propagation_ids" {
  description = "Map of route table propagation names to their IDs"
  value = {
    for name, propagation in aws_ec2_transit_gateway_route_table_propagation.this : name => propagation.id
  }
}

output "route_table_propagation_resource_ids" {
  description = "Map of route table propagation names to their resource IDs"
  value = {
    for name, propagation in aws_ec2_transit_gateway_route_table_propagation.this : name => propagation.resource_id
  }
}

# ============================================================================
# STATIC ROUTE OUTPUTS
# ============================================================================

output "static_route_ids" {
  description = "Map of static route names to their IDs"
  value = {
    for name, route in aws_ec2_transit_gateway_route.this : name => route.id
  }
}

# ============================================================================
# CUSTOMER GATEWAY OUTPUTS
# ============================================================================

output "customer_gateway_ids" {
  description = "Map of Customer Gateway names to their IDs"
  value = {
    for name, cgw in aws_customer_gateway.this : name => cgw.id
  }
}

output "customer_gateway_arns" {
  description = "Map of Customer Gateway names to their ARNs"
  value = {
    for name, cgw in aws_customer_gateway.this : name => cgw.arn
  }
}

# ============================================================================
# VPN CONNECTION OUTPUTS
# ============================================================================

output "vpn_connection_ids" {
  description = "Map of VPN connection names to their IDs"
  value = {
    for name, vpn in aws_vpn_connection.this : name => vpn.id
  }
}

output "vpn_connection_arns" {
  description = "Map of VPN connection names to their ARNs"
  value = {
    for name, vpn in aws_vpn_connection.this : name => vpn.arn
  }
}

output "vpn_connection_tunnel1_addresses" {
  description = "Map of VPN connection names to their tunnel 1 addresses"
  value = {
    for name, vpn in aws_vpn_connection.this : name => vpn.tunnel1_address
  }
}

output "vpn_connection_tunnel2_addresses" {
  description = "Map of VPN connection names to their tunnel 2 addresses"
  value = {
    for name, vpn in aws_vpn_connection.this : name => vpn.tunnel2_address
  }
}

# ============================================================================
# PEERING ATTACHMENT OUTPUTS
# ============================================================================

output "peering_attachment_ids" {
  description = "Map of peering attachment names to their IDs"
  value = {
    for name, peering in aws_ec2_transit_gateway_peering_attachment.this : name => peering.id
  }
}

output "peering_attachment_arns" {
  description = "Map of peering attachment names to their ARNs"
  value = {
    for name, peering in aws_ec2_transit_gateway_peering_attachment.this : name => peering.arn
  }
}

# ============================================================================
# DIRECT CONNECT GATEWAY OUTPUTS
# ============================================================================

output "dx_gateway_association_ids" {
  description = "Map of Direct Connect Gateway association names to their IDs"
  value = {
    for name, dx in aws_dx_gateway_association.this : name => dx.id
  }
}

output "dx_gateway_association_states" {
  description = "Map of Direct Connect Gateway association names to their states"
  value = {
    for name, dx in aws_dx_gateway_association.this : name => dx.associated_gateway_owner_account_id
  }
}

# ============================================================================
# MULTICAST DOMAIN OUTPUTS
# ============================================================================

output "multicast_domain_ids" {
  description = "Map of multicast domain names to their IDs"
  value = {
    for name, domain in aws_ec2_transit_gateway_multicast_domain.this : name => domain.id
  }
}

output "multicast_domain_arns" {
  description = "Map of multicast domain names to their ARNs"
  value = {
    for name, domain in aws_ec2_transit_gateway_multicast_domain.this : name => domain.arn
  }
}

# ============================================================================
# RESOURCE SHARING OUTPUTS
# ============================================================================

output "resource_share_arn" {
  description = "ARN of the Resource Access Manager resource share"
  value       = var.create_transit_gateway && var.enable_resource_sharing ? aws_ram_resource_share.this[0].arn : null
}

output "resource_share_id" {
  description = "ID of the Resource Access Manager resource share"
  value       = var.create_transit_gateway && var.enable_resource_sharing ? aws_ram_resource_share.this[0].id : null
}

output "resource_share_status" {
  description = "Status of the Resource Access Manager resource share"
  value       = var.create_transit_gateway && var.enable_resource_sharing ? aws_ram_resource_share.this[0].status : null
}

# ============================================================================
# FLOW LOGS OUTPUTS
# ============================================================================

output "flow_log_id" {
  description = "ID of the Flow Log"
  value       = var.create_transit_gateway && var.enable_flow_logs ? aws_flow_log.this[0].id : null
}

output "flow_log_arn" {
  description = "ARN of the Flow Log"
  value       = var.create_transit_gateway && var.enable_flow_logs ? aws_flow_log.this[0].arn : null
}

# ============================================================================
# SUMMARY OUTPUTS
# ============================================================================

output "transit_gateway_summary" {
  description = "Summary of Transit Gateway configuration"
  value = var.create_transit_gateway ? {
    id                              = aws_ec2_transit_gateway.this[0].id
    arn                             = aws_ec2_transit_gateway.this[0].arn
    amazon_side_asn                 = aws_ec2_transit_gateway.this[0].amazon_side_asn
    auto_accept_shared_attachments  = aws_ec2_transit_gateway.this[0].auto_accept_shared_attachments
    auto_accept_shared_associations = aws_ec2_transit_gateway.this[0].auto_accept_shared_associations
    default_route_table_association = aws_ec2_transit_gateway.this[0].default_route_table_association
    default_route_table_propagation = aws_ec2_transit_gateway.this[0].default_route_table_propagation
    dns_support                     = aws_ec2_transit_gateway.this[0].dns_support
    vpn_ecmp_support               = aws_ec2_transit_gateway.this[0].vpn_ecmp_support
    multicast_support              = aws_ec2_transit_gateway.this[0].multicast_support
    vpc_attachments_count          = length(aws_ec2_transit_gateway_vpc_attachment.this)
    route_tables_count             = length(aws_ec2_transit_gateway_route_table.this)
    vpn_connections_count          = length(aws_vpn_connection.this)
    peering_attachments_count      = length(aws_ec2_transit_gateway_peering_attachment.this)
  } : null
}

# ============================================================================
# ATTACHMENT DETAILS
# ============================================================================

output "attachment_details" {
  description = "Detailed information about all attachments"
  value = {
    vpc_attachments = {
      for name, attachment in aws_ec2_transit_gateway_vpc_attachment.this : name => {
        id                     = attachment.id
        arn                    = attachment.arn
        vpc_id                 = attachment.vpc_id
        vpc_owner_id           = attachment.vpc_owner_id
        subnet_ids             = attachment.subnet_ids
        dns_support            = attachment.dns_support
        ipv6_support           = attachment.ipv6_support
        appliance_mode_support = attachment.appliance_mode_support
      }
    }
    peering_attachments = {
      for name, peering in aws_ec2_transit_gateway_peering_attachment.this : name => {
        id                      = peering.id
        arn                     = peering.arn
        peer_account_id         = peering.peer_account_id
        peer_region            = peering.peer_region
        peer_transit_gateway_id = peering.peer_transit_gateway_id
      }
    }
  }
}

# ============================================================================
# ROUTING CONFIGURATION
# ============================================================================

output "routing_configuration" {
  description = "Complete routing configuration details"
  value = {
    default_association_route_table_id = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].association_default_route_table_id : null
    default_propagation_route_table_id = var.create_transit_gateway ? aws_ec2_transit_gateway.this[0].propagation_default_route_table_id : null
    custom_route_tables = {
      for name, rt in aws_ec2_transit_gateway_route_table.this : name => {
        id  = rt.id
        arn = rt.arn
      }
    }
    associations = {
      for name, assoc in aws_ec2_transit_gateway_route_table_association.this : name => {
        id                             = assoc.id
        resource_id                    = assoc.resource_id
        resource_type                  = assoc.resource_type
        transit_gateway_route_table_id = assoc.transit_gateway_route_table_id
      }
    }
    propagations = {
      for name, prop in aws_ec2_transit_gateway_route_table_propagation.this : name => {
        id                             = prop.id
        resource_id                    = prop.resource_id
        resource_type                  = prop.resource_type
        transit_gateway_route_table_id = prop.transit_gateway_route_table_id
      }
    }
  }
}