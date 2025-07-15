# ============================================================================
# AWS VPC TRANSIT GATEWAY MODULE VARIABLES
# ============================================================================
# Variable definitions for Transit Gateway configuration
# Supports comprehensive network connectivity and routing features
# ============================================================================

# ============================================================================
# GENERAL CONFIGURATION
# ============================================================================

variable "name" {
  description = "Name of the Transit Gateway"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod) for resource tagging"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Additional tags to apply to all Transit Gateway resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# TRANSIT GATEWAY CONFIGURATION
# ============================================================================

variable "create_transit_gateway" {
  description = "Whether to create the Transit Gateway"
  type        = bool
  default     = true
}

variable "description" {
  description = "Description of the Transit Gateway"
  type        = string
  default     = "Transit Gateway for centralized network connectivity"
}

variable "amazon_side_asn" {
  description = "Private Autonomous System Number (ASN) for the Amazon side of a BGP session"
  type        = number
  default     = 64512

  validation {
    condition     = var.amazon_side_asn >= 64512 && var.amazon_side_asn <= 65534
    error_message = "Amazon side ASN must be between 64512 and 65534."
  }
}

variable "auto_accept_shared_attachments" {
  description = "Whether resource attachment requests are automatically accepted"
  type        = string
  default     = "disable"

  validation {
    condition     = contains(["enable", "disable"], var.auto_accept_shared_attachments)
    error_message = "Auto accept shared attachments must be either 'enable' or 'disable'."
  }
}

variable "auto_accept_shared_associations" {
  description = "Whether resource association requests are automatically accepted"
  type        = string
  default     = "disable"

  validation {
    condition     = contains(["enable", "disable"], var.auto_accept_shared_associations)
    error_message = "Auto accept shared associations must be either 'enable' or 'disable'."
  }
}

variable "default_route_table_association" {
  description = "Whether resource attachments are automatically associated with the default association route table"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_association)
    error_message = "Default route table association must be either 'enable' or 'disable'."
  }
}

variable "default_route_table_propagation" {
  description = "Whether resource attachments automatically propagate routes to the default propagation route table"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_propagation)
    error_message = "Default route table propagation must be either 'enable' or 'disable'."
  }
}

variable "dns_support" {
  description = "Whether DNS support is enabled"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.dns_support)
    error_message = "DNS support must be either 'enable' or 'disable'."
  }
}

variable "vpn_ecmp_support" {
  description = "Whether Equal Cost Multipath Protocol support is enabled"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.vpn_ecmp_support)
    error_message = "VPN ECMP support must be either 'enable' or 'disable'."
  }
}

variable "multicast_support" {
  description = "Whether multicast support is enabled"
  type        = string
  default     = "disable"

  validation {
    condition     = contains(["enable", "disable"], var.multicast_support)
    error_message = "Multicast support must be either 'enable' or 'disable'."
  }
}

variable "transit_gateway_cidr_blocks" {
  description = "One or more IPv4 or IPv6 CIDR blocks for the transit gateway"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.transit_gateway_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid."
  }
}

# ============================================================================
# VPC ATTACHMENTS CONFIGURATION
# ============================================================================

variable "vpc_attachments" {
  description = "Map of VPC attachments to create"
  type = map(object({
    vpc_id                 = string
    subnet_ids             = list(string)
    dns_support            = optional(string, "enable")
    ipv6_support           = optional(string, "disable")
    appliance_mode_support = optional(string, "disable")
    tags                   = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, attachment in var.vpc_attachments : contains(["enable", "disable"], attachment.dns_support)
    ])
    error_message = "VPC attachment DNS support must be either 'enable' or 'disable'."
  }

  validation {
    condition = alltrue([
      for name, attachment in var.vpc_attachments : contains(["enable", "disable"], attachment.ipv6_support)
    ])
    error_message = "VPC attachment IPv6 support must be either 'enable' or 'disable'."
  }

  validation {
    condition = alltrue([
      for name, attachment in var.vpc_attachments : contains(["enable", "disable"], attachment.appliance_mode_support)
    ])
    error_message = "VPC attachment appliance mode support must be either 'enable' or 'disable'."
  }
}

# ============================================================================
# ROUTE TABLES CONFIGURATION
# ============================================================================

variable "route_tables" {
  description = "Map of custom route tables to create"
  type = map(object({
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "route_table_associations" {
  description = "Map of route table associations"
  type = map(object({
    attachment_name    = string
    attachment_type    = string
    attachment_id      = optional(string)
    route_table_name   = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, association in var.route_table_associations : contains(["vpc", "vpn", "dx", "peering"], association.attachment_type)
    ])
    error_message = "Attachment type must be one of: vpc, vpn, dx, peering."
  }
}

variable "route_table_propagations" {
  description = "Map of route table propagations"
  type = map(object({
    attachment_name    = string
    attachment_type    = string
    attachment_id      = optional(string)
    route_table_name   = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, propagation in var.route_table_propagations : contains(["vpc", "vpn", "dx", "peering"], propagation.attachment_type)
    ])
    error_message = "Attachment type must be one of: vpc, vpn, dx, peering."
  }
}

variable "static_routes" {
  description = "Map of static routes to create"
  type = map(object({
    destination_cidr_block = string
    route_table_name       = string
    attachment_name        = string
    attachment_type        = string
    attachment_id          = optional(string)
    blackhole              = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, route in var.static_routes : can(cidrhost(route.destination_cidr_block, 0))
    ])
    error_message = "All destination CIDR blocks must be valid."
  }
}

# ============================================================================
# DIRECT CONNECT CONFIGURATION
# ============================================================================

variable "enable_dx_gateway_association" {
  description = "Whether to enable Direct Connect Gateway association"
  type        = bool
  default     = false
}

variable "dx_gateway_associations" {
  description = "Map of Direct Connect Gateway associations"
  type = map(object({
    dx_gateway_id    = string
    allowed_prefixes = optional(list(string), [])
  }))
  default = {}
}

# ============================================================================
# VPN CONFIGURATION
# ============================================================================

variable "customer_gateways" {
  description = "Map of Customer Gateways to create"
  type = map(object({
    bgp_asn     = number
    ip_address  = string
    type        = string
    device_name = optional(string)
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, cgw in var.customer_gateways : contains(["ipsec.1"], cgw.type)
    ])
    error_message = "Customer Gateway type must be 'ipsec.1'."
  }
}

variable "vpn_connections" {
  description = "Map of VPN connections to create"
  type = map(object({
    customer_gateway_id   = string
    type                 = string
    static_routes_only   = optional(bool, false)
    tunnel1_inside_cidr  = optional(string)
    tunnel2_inside_cidr  = optional(string)
    tunnel1_preshared_key = optional(string)
    tunnel2_preshared_key = optional(string)
    tags                 = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, vpn in var.vpn_connections : contains(["ipsec.1"], vpn.type)
    ])
    error_message = "VPN connection type must be 'ipsec.1'."
  }
}

# ============================================================================
# PEERING CONFIGURATION
# ============================================================================

variable "peering_attachments" {
  description = "Map of Transit Gateway peering attachments"
  type = map(object({
    peer_account_id         = string
    peer_region            = string
    peer_transit_gateway_id = string
    tags                   = optional(map(string), {})
  }))
  default = {}
}

# ============================================================================
# MULTICAST CONFIGURATION
# ============================================================================

variable "enable_multicast" {
  description = "Whether to enable multicast domains"
  type        = bool
  default     = false
}

variable "multicast_domains" {
  description = "Map of multicast domains to create"
  type = map(object({
    auto_accept_shared_associations = optional(string, "disable")
    igmp_support                   = optional(string, "enable")
    static_sources_support         = optional(string, "disable")
    tags                          = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, domain in var.multicast_domains : contains(["enable", "disable"], domain.auto_accept_shared_associations)
    ])
    error_message = "Auto accept shared associations must be either 'enable' or 'disable'."
  }

  validation {
    condition = alltrue([
      for name, domain in var.multicast_domains : contains(["enable", "disable"], domain.igmp_support)
    ])
    error_message = "IGMP support must be either 'enable' or 'disable'."
  }

  validation {
    condition = alltrue([
      for name, domain in var.multicast_domains : contains(["enable", "disable"], domain.static_sources_support)
    ])
    error_message = "Static sources support must be either 'enable' or 'disable'."
  }
}

# ============================================================================
# RESOURCE SHARING CONFIGURATION
# ============================================================================

variable "enable_resource_sharing" {
  description = "Whether to enable resource sharing via RAM"
  type        = bool
  default     = false
}

variable "allow_external_principals" {
  description = "Whether to allow sharing with external principals"
  type        = bool
  default     = false
}

variable "shared_principals" {
  description = "List of principals to share the Transit Gateway with"
  type        = list(string)
  default     = []
}

# ============================================================================
# FLOW LOGS CONFIGURATION
# ============================================================================

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs for the Transit Gateway"
  type        = bool
  default     = false
}

variable "flow_logs_iam_role_arn" {
  description = "IAM role ARN for Flow Logs"
  type        = string
  default     = null
}

variable "flow_logs_destination_arn" {
  description = "ARN of the destination for Flow Logs (CloudWatch Logs or S3)"
  type        = string
  default     = null
}

variable "flow_logs_destination_type" {
  description = "Type of destination for Flow Logs (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination_type)
    error_message = "Flow logs destination type must be either 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_logs_log_format" {
  description = "Format for Flow Logs"
  type        = string
  default     = null
}

variable "flow_logs_max_aggregation_interval" {
  description = "Maximum interval of time during which a flow of packets is captured and aggregated into a flow log record"
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_logs_max_aggregation_interval)
    error_message = "Flow logs max aggregation interval must be either 60 or 600 seconds."
  }
}

variable "flow_logs_traffic_type" {
  description = "Type of traffic to capture in Flow Logs"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "Flow logs traffic type must be one of: ACCEPT, REJECT, ALL."
  }
}