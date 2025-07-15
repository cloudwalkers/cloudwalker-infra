# ============================================================================
# AWS VPC TRANSIT GATEWAY MODULE
# ============================================================================
# This module creates and manages AWS Transit Gateway for scalable network
# connectivity between VPCs, on-premises networks, and AWS services.
# Transit Gateway provides:
# - Centralized connectivity hub for multiple VPCs and networks
# - Simplified network architecture and routing management
# - Support for cross-region peering and multi-account connectivity
# - Advanced routing with route tables and propagation
# - Integration with Direct Connect and VPN connections
# ============================================================================

# ============================================================================
# TRANSIT GATEWAY
# ============================================================================
# Central hub for network connectivity
# Provides scalable and flexible inter-VPC and hybrid connectivity
# Supports advanced routing and network segmentation
resource "aws_ec2_transit_gateway" "this" {
  count = var.create_transit_gateway ? 1 : 0

  description                     = var.description
  amazon_side_asn                = var.amazon_side_asn
  auto_accept_shared_attachments = var.auto_accept_shared_attachments
  auto_accept_shared_associations = var.auto_accept_shared_associations
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
  dns_support                    = var.dns_support
  vpn_ecmp_support              = var.vpn_ecmp_support
  multicast_support             = var.multicast_support
  transit_gateway_cidr_blocks   = var.transit_gateway_cidr_blocks

  tags = merge(
    var.tags,
    {
      Name        = var.name
      Environment = var.environment
      Module      = "transit-gateway"
    }
  )
}

# ============================================================================
# VPC ATTACHMENTS
# ============================================================================
# Attach VPCs to the Transit Gateway
# Enables connectivity between attached VPCs through the gateway
# Supports subnet selection and DNS resolution
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each = var.create_transit_gateway ? var.vpc_attachments : {}

  transit_gateway_id     = aws_ec2_transit_gateway.this[0].id
  vpc_id                = each.value.vpc_id
  subnet_ids            = each.value.subnet_ids
  dns_support           = each.value.dns_support
  ipv6_support          = each.value.ipv6_support
  appliance_mode_support = each.value.appliance_mode_support

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name}-${each.key}-attachment"
      Environment = var.environment
      Module      = "transit-gateway"
      Type        = "vpc-attachment"
      VPC         = each.value.vpc_id
    }
  )
}

# ============================================================================
# CUSTOM ROUTE TABLES
# ============================================================================
# Custom route tables for advanced routing scenarios
# Enables network segmentation and traffic isolation
# Supports propagation and association with attachments
resource "aws_ec2_transit_gateway_route_table" "this" {
  for_each = var.create_transit_gateway ? var.route_tables : {}

  transit_gateway_id = aws_ec2_transit_gateway.this[0].id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name}-${each.key}-rt"
      Environment = var.environment
      Module      = "transit-gateway"
      Type        = "route-table"
    }
  )
}

# ============================================================================
# ROUTE TABLE ASSOCIATIONS
# ============================================================================
# Associate attachments with specific route tables
# Controls which route table an attachment uses for routing decisions
resource "aws_ec2_transit_gateway_route_table_association" "this" {
  for_each = var.create_transit_gateway ? var.route_table_associations : {}

  transit_gateway_attachment_id  = each.value.attachment_type == "vpc" ? aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment_name].id : each.value.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id
}

# ============================================================================
# ROUTE TABLE PROPAGATIONS
# ============================================================================
# Enable route propagation from attachments to route tables
# Automatically adds routes for attached networks
resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = var.create_transit_gateway ? var.route_table_propagations : {}

  transit_gateway_attachment_id  = each.value.attachment_type == "vpc" ? aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment_name].id : each.value.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id
}

# ============================================================================
# STATIC ROUTES
# ============================================================================
# Static routes for specific routing requirements
# Enables custom routing policies and traffic steering
resource "aws_ec2_transit_gateway_route" "this" {
  for_each = var.create_transit_gateway ? var.static_routes : {}

  destination_cidr_block         = each.value.destination_cidr_block
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.this[each.value.route_table_name].id
  transit_gateway_attachment_id  = each.value.attachment_type == "vpc" ? aws_ec2_transit_gateway_vpc_attachment.this[each.value.attachment_name].id : each.value.attachment_id
  blackhole                     = each.value.blackhole
}

# ============================================================================
# DIRECT CONNECT GATEWAY ASSOCIATION
# ============================================================================
# Associate Direct Connect Gateway with Transit Gateway
# Enables hybrid connectivity to on-premises networks
resource "aws_dx_gateway_association" "this" {
  for_each = var.create_transit_gateway && var.enable_dx_gateway_association ? var.dx_gateway_associations : {}

  dx_gateway_id         = each.value.dx_gateway_id
  associated_gateway_id = aws_ec2_transit_gateway.this[0].id
  allowed_prefixes      = each.value.allowed_prefixes

  timeouts {
    create = "30m"
    delete = "30m"
  }
}

# ============================================================================
# VPN CONNECTIONS
# ============================================================================
# Site-to-Site VPN connections through Transit Gateway
# Provides encrypted connectivity to on-premises networks
resource "aws_vpn_connection" "this" {
  for_each = var.create_transit_gateway ? var.vpn_connections : {}

  customer_gateway_id   = each.value.customer_gateway_id
  transit_gateway_id    = aws_ec2_transit_gateway.this[0].id
  type                 = each.value.type
  static_routes_only   = each.value.static_routes_only
  tunnel1_inside_cidr  = each.value.tunnel1_inside_cidr
  tunnel2_inside_cidr  = each.value.tunnel2_inside_cidr
  tunnel1_preshared_key = each.value.tunnel1_preshared_key
  tunnel2_preshared_key = each.value.tunnel2_preshared_key

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name}-${each.key}-vpn"
      Environment = var.environment
      Module      = "transit-gateway"
      Type        = "vpn-connection"
    }
  )
}

# ============================================================================
# CUSTOMER GATEWAYS
# ============================================================================
# Customer Gateway definitions for VPN connections
# Represents on-premises VPN devices or software
resource "aws_customer_gateway" "this" {
  for_each = var.create_transit_gateway ? var.customer_gateways : {}

  bgp_asn    = each.value.bgp_asn
  ip_address = each.value.ip_address
  type       = each.value.type
  device_name = each.value.device_name

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name}-${each.key}-cgw"
      Environment = var.environment
      Module      = "transit-gateway"
      Type        = "customer-gateway"
    }
  )
}

# ============================================================================
# TRANSIT GATEWAY PEERING
# ============================================================================
# Cross-region Transit Gateway peering connections
# Enables connectivity between Transit Gateways in different regions
resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  for_each = var.create_transit_gateway ? var.peering_attachments : {}

  peer_account_id         = each.value.peer_account_id
  peer_region            = each.value.peer_region
  peer_transit_gateway_id = each.value.peer_transit_gateway_id
  transit_gateway_id     = aws_ec2_transit_gateway.this[0].id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name}-${each.key}-peering"
      Environment = var.environment
      Module      = "transit-gateway"
      Type        = "peering-attachment"
    }
  )
}

# ============================================================================
# TRANSIT GATEWAY MULTICAST DOMAIN
# ============================================================================
# Multicast domain for multicast traffic support
# Enables efficient one-to-many communication patterns
resource "aws_ec2_transit_gateway_multicast_domain" "this" {
  for_each = var.create_transit_gateway && var.enable_multicast ? var.multicast_domains : {}

  transit_gateway_id                     = aws_ec2_transit_gateway.this[0].id
  auto_accept_shared_associations       = each.value.auto_accept_shared_associations
  igmp_support                          = each.value.igmp_support
  static_sources_support                = each.value.static_sources_support

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name}-${each.key}-multicast"
      Environment = var.environment
      Module      = "transit-gateway"
      Type        = "multicast-domain"
    }
  )
}

# ============================================================================
# RESOURCE ACCESS MANAGER SHARING
# ============================================================================
# Share Transit Gateway with other AWS accounts
# Enables cross-account connectivity and resource sharing
resource "aws_ram_resource_share" "this" {
  count = var.create_transit_gateway && var.enable_resource_sharing ? 1 : 0

  name                      = "${var.name}-tgw-share"
  description              = "Transit Gateway resource share for ${var.name}"
  allow_external_principals = var.allow_external_principals

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-tgw-share"
      Environment = var.environment
      Module      = "transit-gateway"
      Type        = "resource-share"
    }
  )
}

resource "aws_ram_resource_association" "this" {
  count = var.create_transit_gateway && var.enable_resource_sharing ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.this[0].arn
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

resource "aws_ram_principal_association" "this" {
  for_each = var.create_transit_gateway && var.enable_resource_sharing ? toset(var.shared_principals) : []

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this[0].arn
}

# ============================================================================
# FLOW LOGS
# ============================================================================
# VPC Flow Logs for Transit Gateway traffic monitoring
# Provides visibility into network traffic patterns and security
resource "aws_flow_log" "this" {
  count = var.create_transit_gateway && var.enable_flow_logs ? 1 : 0

  iam_role_arn             = var.flow_logs_iam_role_arn
  log_destination          = var.flow_logs_destination_arn
  log_destination_type     = var.flow_logs_destination_type
  log_format              = var.flow_logs_log_format
  max_aggregation_interval = var.flow_logs_max_aggregation_interval
  traffic_type            = var.flow_logs_traffic_type
  transit_gateway_id      = aws_ec2_transit_gateway.this[0].id

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-flow-logs"
      Environment = var.environment
      Module      = "transit-gateway"
      Type        = "flow-logs"
    }
  )
}