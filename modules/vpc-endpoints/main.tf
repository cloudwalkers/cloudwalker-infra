# ============================================================================
# AWS VPC ENDPOINTS MODULE
# ============================================================================
# This module creates and manages AWS VPC endpoints for secure, private
# connectivity to AWS services without traversing the public internet.
# VPC endpoints provide:
# - Private connectivity to AWS services within your VPC
# - Reduced data transfer costs and improved security
# - Two types: Gateway endpoints and Interface endpoints
# - Policy-based access control for fine-grained permissions
# - DNS resolution for seamless service integration
# ============================================================================

# ============================================================================
# DATA SOURCES
# ============================================================================
# Retrieve information about available VPC endpoint services
# Used for validation and dynamic endpoint creation

data "aws_vpc_endpoint_service" "this" {
  for_each = var.endpoints

  service      = each.value.service_name
  service_type = each.value.vpc_endpoint_type
}

data "aws_route_tables" "private" {
  count = var.auto_accept && length(var.route_table_ids) == 0 ? 1 : 0

  vpc_id = var.vpc_id

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

# ============================================================================
# INTERFACE VPC ENDPOINTS
# ============================================================================
# Interface endpoints for AWS services that support ENI-based connectivity
# Provides private IP addresses within your VPC for service access
# Supports security groups and DNS resolution
resource "aws_vpc_endpoint" "interface" {
  for_each = {
    for name, config in var.endpoints : name => config
    if config.vpc_endpoint_type == "Interface"
  }

  vpc_id              = var.vpc_id
  service_name        = data.aws_vpc_endpoint_service.this[each.key].service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = each.value.subnet_ids
  security_group_ids  = each.value.security_group_ids
  policy              = each.value.policy
  private_dns_enabled = each.value.private_dns_enabled
  route_table_ids     = each.value.route_table_ids

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name_prefix}-${each.key}-endpoint"
      Environment = var.environment
      Module      = "vpc-endpoints"
      Type        = "Interface"
      Service     = each.value.service_name
    }
  )

  # Ensure the endpoint service exists and is available
  depends_on = [data.aws_vpc_endpoint_service.this]
}

# ============================================================================
# GATEWAY VPC ENDPOINTS
# ============================================================================
# Gateway endpoints for S3 and DynamoDB services
# Routes traffic through route table entries without ENIs
# No additional charges for data processing or hourly usage
resource "aws_vpc_endpoint" "gateway" {
  for_each = {
    for name, config in var.endpoints : name => config
    if config.vpc_endpoint_type == "Gateway"
  }

  vpc_id            = var.vpc_id
  service_name      = data.aws_vpc_endpoint_service.this[each.key].service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = length(each.value.route_table_ids) > 0 ? each.value.route_table_ids : (var.auto_accept ? data.aws_route_tables.private[0].ids : [])
  policy            = each.value.policy

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name_prefix}-${each.key}-endpoint"
      Environment = var.environment
      Module      = "vpc-endpoints"
      Type        = "Gateway"
      Service     = each.value.service_name
    }
  )

  depends_on = [data.aws_vpc_endpoint_service.this]
}

# ============================================================================
# SECURITY GROUP FOR INTERFACE ENDPOINTS
# ============================================================================
# Default security group for interface endpoints when not specified
# Allows HTTPS traffic from VPC CIDR blocks
resource "aws_security_group" "vpc_endpoint" {
  count = var.create_security_group ? 1 : 0

  name_prefix = "${var.name_prefix}-vpc-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  # HTTPS ingress from VPC
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTP ingress from VPC (for some services)
  dynamic "ingress" {
    for_each = var.allow_http ? [1] : []
    content {
      description = "HTTP from VPC"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-vpc-endpoints-sg"
      Environment = var.environment
      Module      = "vpc-endpoints"
      Purpose     = "vpc-endpoint-access"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# ROUTE 53 RESOLVER RULES (Optional)
# ============================================================================
# Custom DNS resolution rules for VPC endpoints
# Enables custom domain name resolution for private endpoints
resource "aws_route53_resolver_rule" "vpc_endpoint" {
  for_each = var.create_resolver_rules ? var.resolver_rules : {}

  domain_name          = each.value.domain_name
  name                 = "${var.name_prefix}-${each.key}-resolver-rule"
  rule_type            = each.value.rule_type
  resolver_endpoint_id = each.value.resolver_endpoint_id

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
      Name        = "${var.name_prefix}-${each.key}-resolver-rule"
      Environment = var.environment
      Module      = "vpc-endpoints"
    }
  )
}

# ============================================================================
# ROUTE 53 RESOLVER RULE ASSOCIATIONS
# ============================================================================
# Associates resolver rules with VPCs
# Enables custom DNS resolution within the VPC
resource "aws_route53_resolver_rule_association" "vpc_endpoint" {
  for_each = var.create_resolver_rules ? var.resolver_rules : {}

  resolver_rule_id = aws_route53_resolver_rule.vpc_endpoint[each.key].id
  vpc_id           = var.vpc_id
}

# ============================================================================
# VPC ENDPOINT NOTIFICATIONS (Optional)
# ============================================================================
# CloudWatch Events for VPC endpoint state changes
# Enables monitoring and alerting on endpoint status
resource "aws_cloudwatch_event_rule" "vpc_endpoint_state" {
  count = var.enable_endpoint_monitoring ? 1 : 0

  name        = "${var.name_prefix}-vpc-endpoint-state-changes"
  description = "Capture VPC endpoint state changes"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["VPC Endpoint State Change"]
    detail = {
      state = ["available", "failed", "pending", "deleting"]
    }
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-vpc-endpoint-monitoring"
      Environment = var.environment
      Module      = "vpc-endpoints"
    }
  )
}

# ============================================================================
# CLOUDWATCH EVENT TARGET (Optional)
# ============================================================================
# SNS topic target for VPC endpoint state change notifications
resource "aws_cloudwatch_event_target" "vpc_endpoint_sns" {
  count = var.enable_endpoint_monitoring && var.monitoring_sns_topic_arn != null ? 1 : 0

  rule      = aws_cloudwatch_event_rule.vpc_endpoint_state[0].name
  target_id = "VPCEndpointSNSTarget"
  arn       = var.monitoring_sns_topic_arn
}