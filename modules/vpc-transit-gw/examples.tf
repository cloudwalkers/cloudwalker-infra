# ============================================================================
# AWS VPC TRANSIT GATEWAY MODULE USAGE EXAMPLES
# ============================================================================
# Comprehensive examples showing different Transit Gateway configurations
# These examples demonstrate various use cases and best practices
# ============================================================================

# ============================================================================
# EXAMPLE 1: BASIC TRANSIT GATEWAY WITH VPC ATTACHMENTS
# ============================================================================
# Simple Transit Gateway connecting multiple VPCs
# Suitable for basic multi-VPC connectivity scenarios

module "basic_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "basic-tgw"
  environment = "dev"
  description = "Basic Transit Gateway for VPC connectivity"

  # Basic configuration
  amazon_side_asn = 64512
  dns_support     = "enable"

  # VPC attachments
  vpc_attachments = {
    vpc_a = {
      vpc_id     = module.vpc_a.vpc_id
      subnet_ids = module.vpc_a.private_subnet_ids
      tags = {
        VPC = "vpc-a"
      }
    }
    vpc_b = {
      vpc_id     = module.vpc_b.vpc_id
      subnet_ids = module.vpc_b.private_subnet_ids
      tags = {
        VPC = "vpc-b"
      }
    }
    vpc_c = {
      vpc_id     = module.vpc_c.vpc_id
      subnet_ids = module.vpc_c.private_subnet_ids
      tags = {
        VPC = "vpc-c"
      }
    }
  }

  tags = {
    Project = "BasicNetworking"
    Purpose = "vpc-connectivity"
  }
}

# ============================================================================
# EXAMPLE 2: ENTERPRISE TRANSIT GATEWAY WITH CUSTOM ROUTING
# ============================================================================
# Advanced Transit Gateway with custom route tables and segmentation
# Demonstrates network segmentation and advanced routing

module "enterprise_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "enterprise-tgw"
  environment = "prod"
  description = "Enterprise Transit Gateway with advanced routing"

  # Advanced configuration
  amazon_side_asn                     = 64512
  auto_accept_shared_attachments      = "disable"
  default_route_table_association     = "disable"
  default_route_table_propagation     = "disable"
  dns_support                        = "enable"
  vpn_ecmp_support                   = "enable"

  # VPC attachments
  vpc_attachments = {
    production = {
      vpc_id     = module.prod_vpc.vpc_id
      subnet_ids = module.prod_vpc.private_subnet_ids
      tags = {
        Environment = "production"
        Tier        = "application"
      }
    }
    staging = {
      vpc_id     = module.staging_vpc.vpc_id
      subnet_ids = module.staging_vpc.private_subnet_ids
      tags = {
        Environment = "staging"
        Tier        = "application"
      }
    }
    shared_services = {
      vpc_id     = module.shared_vpc.vpc_id
      subnet_ids = module.shared_vpc.private_subnet_ids
      tags = {
        Environment = "shared"
        Tier        = "services"
      }
    }
    security = {
      vpc_id     = module.security_vpc.vpc_id
      subnet_ids = module.security_vpc.private_subnet_ids
      tags = {
        Environment = "security"
        Tier        = "inspection"
      }
    }
  }

  # Custom route tables for segmentation
  route_tables = {
    production = {
      tags = {
        Environment = "production"
        Purpose     = "prod-routing"
      }
    }
    non_production = {
      tags = {
        Environment = "non-production"
        Purpose     = "dev-staging-routing"
      }
    }
    shared_services = {
      tags = {
        Environment = "shared"
        Purpose     = "shared-services-routing"
      }
    }
    security = {
      tags = {
        Environment = "security"
        Purpose     = "security-inspection"
      }
    }
  }

  # Route table associations
  route_table_associations = {
    prod_association = {
      attachment_name  = "production"
      attachment_type  = "vpc"
      route_table_name = "production"
    }
    staging_association = {
      attachment_name  = "staging"
      attachment_type  = "vpc"
      route_table_name = "non_production"
    }
    shared_association = {
      attachment_name  = "shared_services"
      attachment_type  = "vpc"
      route_table_name = "shared_services"
    }
    security_association = {
      attachment_name  = "security"
      attachment_type  = "vpc"
      route_table_name = "security"
    }
  }

  # Route propagations
  route_table_propagations = {
    prod_to_shared = {
      attachment_name  = "shared_services"
      attachment_type  = "vpc"
      route_table_name = "production"
    }
    staging_to_shared = {
      attachment_name  = "shared_services"
      attachment_type  = "vpc"
      route_table_name = "non_production"
    }
    shared_to_all = {
      attachment_name  = "shared_services"
      attachment_type  = "vpc"
      route_table_name = "shared_services"
    }
  }

  tags = {
    Environment  = "production"
    Architecture = "enterprise"
    Segmentation = "enabled"
  }
}

# ============================================================================
# EXAMPLE 3: HYBRID CONNECTIVITY WITH VPN
# ============================================================================
# Transit Gateway with Site-to-Site VPN connections
# Enables secure connectivity to on-premises networks

module "hybrid_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "hybrid-tgw"
  environment = "prod"
  description = "Hybrid Transit Gateway with VPN connectivity"

  # Configuration optimized for hybrid connectivity
  amazon_side_asn      = 64512
  dns_support         = "enable"
  vpn_ecmp_support    = "enable"

  # VPC attachments
  vpc_attachments = {
    main_vpc = {
      vpc_id     = module.main_vpc.vpc_id
      subnet_ids = module.main_vpc.private_subnet_ids
    }
    dmz_vpc = {
      vpc_id     = module.dmz_vpc.vpc_id
      subnet_ids = module.dmz_vpc.private_subnet_ids
    }
  }

  # Customer Gateways for on-premises connectivity
  customer_gateways = {
    headquarters = {
      bgp_asn     = 65000
      ip_address  = "203.0.113.12"
      type        = "ipsec.1"
      device_name = "HQ-Firewall-01"
      tags = {
        Location = "headquarters"
        Type     = "primary"
      }
    }
    branch_office = {
      bgp_asn     = 65001
      ip_address  = "203.0.113.34"
      type        = "ipsec.1"
      device_name = "Branch-Router-01"
      tags = {
        Location = "branch-office"
        Type     = "secondary"
      }
    }
  }

  # VPN connections
  vpn_connections = {
    hq_vpn = {
      customer_gateway_id = "headquarters"
      type               = "ipsec.1"
      static_routes_only = false
      tags = {
        Location = "headquarters"
        Priority = "primary"
      }
    }
    branch_vpn = {
      customer_gateway_id = "branch_office"
      type               = "ipsec.1"
      static_routes_only = false
      tags = {
        Location = "branch-office"
        Priority = "secondary"
      }
    }
  }

  # Custom route table for hybrid routing
  route_tables = {
    hybrid = {
      tags = {
        Purpose = "hybrid-connectivity"
      }
    }
  }

  tags = {
    Environment = "production"
    Connectivity = "hybrid"
    VPN         = "enabled"
  }
}

# ============================================================================
# EXAMPLE 4: MULTI-REGION TRANSIT GATEWAY WITH PEERING
# ============================================================================
# Transit Gateway with cross-region peering
# Enables global network connectivity

module "multi_region_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "global-tgw-us-west"
  environment = "prod"
  description = "Multi-region Transit Gateway with peering"

  # Configuration for multi-region setup
  amazon_side_asn = 64512
  dns_support     = "enable"

  # VPC attachments in primary region
  vpc_attachments = {
    us_west_prod = {
      vpc_id     = module.us_west_prod_vpc.vpc_id
      subnet_ids = module.us_west_prod_vpc.private_subnet_ids
      tags = {
        Region = "us-west-2"
        Tier   = "production"
      }
    }
    us_west_shared = {
      vpc_id     = module.us_west_shared_vpc.vpc_id
      subnet_ids = module.us_west_shared_vpc.private_subnet_ids
      tags = {
        Region = "us-west-2"
        Tier   = "shared"
      }
    }
  }

  # Cross-region peering
  peering_attachments = {
    us_east_peering = {
      peer_account_id         = data.aws_caller_identity.current.account_id
      peer_region            = "us-east-1"
      peer_transit_gateway_id = "tgw-0123456789abcdef0"  # TGW in us-east-1
      tags = {
        PeerRegion = "us-east-1"
        Purpose    = "cross-region-connectivity"
      }
    }
    eu_west_peering = {
      peer_account_id         = data.aws_caller_identity.current.account_id
      peer_region            = "eu-west-1"
      peer_transit_gateway_id = "tgw-0987654321fedcba0"  # TGW in eu-west-1
      tags = {
        PeerRegion = "eu-west-1"
        Purpose    = "global-connectivity"
      }
    }
  }

  # Custom routing for multi-region
  route_tables = {
    global = {
      tags = {
        Purpose = "global-routing"
        Scope   = "multi-region"
      }
    }
    regional = {
      tags = {
        Purpose = "regional-routing"
        Scope   = "us-west-2"
      }
    }
  }

  tags = {
    Environment = "production"
    Scope       = "global"
    Regions     = "us-west-2,us-east-1,eu-west-1"
  }
}

# ============================================================================
# EXAMPLE 5: SECURE TRANSIT GATEWAY WITH INSPECTION
# ============================================================================
# Transit Gateway with security inspection and monitoring
# Includes flow logs and centralized security controls

module "secure_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "secure-tgw"
  environment = "prod"
  description = "Secure Transit Gateway with inspection and monitoring"

  # Security-focused configuration
  amazon_side_asn                     = 64512
  auto_accept_shared_attachments      = "disable"
  default_route_table_association     = "disable"
  default_route_table_propagation     = "disable"
  dns_support                        = "enable"

  # VPC attachments including security VPC
  vpc_attachments = {
    application = {
      vpc_id                 = module.app_vpc.vpc_id
      subnet_ids             = module.app_vpc.private_subnet_ids
      appliance_mode_support = "enable"
      tags = {
        Tier = "application"
      }
    }
    security_inspection = {
      vpc_id                 = module.security_vpc.vpc_id
      subnet_ids             = module.security_vpc.private_subnet_ids
      appliance_mode_support = "enable"
      tags = {
        Tier = "security"
        Type = "inspection"
      }
    }
    management = {
      vpc_id     = module.mgmt_vpc.vpc_id
      subnet_ids = module.mgmt_vpc.private_subnet_ids
      tags = {
        Tier = "management"
      }
    }
  }

  # Security-focused route tables
  route_tables = {
    inspection = {
      tags = {
        Purpose = "security-inspection"
        Type    = "firewall-routing"
      }
    }
    application = {
      tags = {
        Purpose = "application-routing"
        Type    = "workload-routing"
      }
    }
    management = {
      tags = {
        Purpose = "management-routing"
        Type    = "admin-routing"
      }
    }
  }

  # Static routes for inspection
  static_routes = {
    app_to_inspection = {
      destination_cidr_block = "0.0.0.0/0"
      route_table_name      = "application"
      attachment_name       = "security_inspection"
      attachment_type       = "vpc"
    }
    inspection_to_internet = {
      destination_cidr_block = "10.0.0.0/8"
      route_table_name      = "inspection"
      attachment_name       = "application"
      attachment_type       = "vpc"
    }
  }

  # Enable flow logs for monitoring
  enable_flow_logs                     = true
  flow_logs_destination_type           = "cloud-watch-logs"
  flow_logs_destination_arn           = module.cloudwatch_logs.log_group_arn
  flow_logs_iam_role_arn              = module.flow_logs_role.arn
  flow_logs_traffic_type              = "ALL"
  flow_logs_max_aggregation_interval  = 60

  tags = {
    Environment = "production"
    Security    = "inspection-enabled"
    Monitoring  = "flow-logs-enabled"
    Compliance  = "required"
  }
}

# ============================================================================
# EXAMPLE 6: SHARED SERVICES TRANSIT GATEWAY
# ============================================================================
# Transit Gateway shared across multiple AWS accounts
# Uses Resource Access Manager for cross-account sharing

module "shared_services_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "shared-services-tgw"
  environment = "prod"
  description = "Shared services Transit Gateway for multi-account architecture"

  # Configuration for shared services
  amazon_side_asn                = 64512
  auto_accept_shared_attachments = "enable"
  dns_support                   = "enable"

  # Central shared services VPC
  vpc_attachments = {
    shared_services = {
      vpc_id     = module.shared_services_vpc.vpc_id
      subnet_ids = module.shared_services_vpc.private_subnet_ids
      tags = {
        Purpose = "shared-services"
        Type    = "central-services"
      }
    }
    dns_resolver = {
      vpc_id     = module.dns_vpc.vpc_id
      subnet_ids = module.dns_vpc.private_subnet_ids
      tags = {
        Purpose = "dns-resolution"
        Type    = "infrastructure"
      }
    }
  }

  # Enable resource sharing
  enable_resource_sharing    = true
  allow_external_principals  = false
  shared_principals = [
    "123456789012",  # Production account
    "123456789013",  # Development account
    "123456789014",  # Security account
  ]

  # Custom route table for shared services
  route_tables = {
    shared_services = {
      tags = {
        Purpose = "shared-services-routing"
        Scope   = "multi-account"
      }
    }
  }

  tags = {
    Environment = "shared"
    Purpose     = "shared-services"
    Sharing     = "cross-account"
    Accounts    = "prod,dev,security"
  }
}

# ============================================================================
# EXAMPLE 7: DEVELOPMENT ENVIRONMENT TRANSIT GATEWAY
# ============================================================================
# Simplified Transit Gateway for development environments
# Cost-optimized configuration with basic features

module "dev_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "dev-tgw"
  environment = "dev"
  description = "Development Transit Gateway for testing and development"

  # Basic configuration for development
  amazon_side_asn = 64512
  dns_support     = "enable"

  # Development VPC attachments
  vpc_attachments = {
    dev_app = {
      vpc_id     = module.dev_app_vpc.vpc_id
      subnet_ids = module.dev_app_vpc.private_subnet_ids
      tags = {
        Environment = "development"
        Application = "web-app"
      }
    }
    dev_data = {
      vpc_id     = module.dev_data_vpc.vpc_id
      subnet_ids = module.dev_data_vpc.private_subnet_ids
      tags = {
        Environment = "development"
        Application = "database"
      }
    }
    dev_shared = {
      vpc_id     = module.dev_shared_vpc.vpc_id
      subnet_ids = module.dev_shared_vpc.private_subnet_ids
      tags = {
        Environment = "development"
        Purpose     = "shared-tools"
      }
    }
  }

  tags = {
    Environment   = "development"
    CostOptimized = "true"
    Purpose       = "testing"
  }
}

# ============================================================================
# EXAMPLE 8: MULTICAST-ENABLED TRANSIT GATEWAY
# ============================================================================
# Transit Gateway with multicast support
# Enables efficient one-to-many communication patterns

module "multicast_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "multicast-tgw"
  environment = "prod"
  description = "Transit Gateway with multicast support for media streaming"

  # Enable multicast support
  amazon_side_asn   = 64512
  dns_support       = "enable"
  multicast_support = "enable"

  # VPC attachments for multicast applications
  vpc_attachments = {
    media_source = {
      vpc_id     = module.media_source_vpc.vpc_id
      subnet_ids = module.media_source_vpc.private_subnet_ids
      tags = {
        Purpose = "media-source"
        Type    = "multicast-sender"
      }
    }
    media_receivers = {
      vpc_id     = module.media_receivers_vpc.vpc_id
      subnet_ids = module.media_receivers_vpc.private_subnet_ids
      tags = {
        Purpose = "media-receivers"
        Type    = "multicast-receivers"
      }
    }
  }

  # Enable multicast domains
  enable_multicast = true
  multicast_domains = {
    media_streaming = {
      auto_accept_shared_associations = "enable"
      igmp_support                   = "enable"
      static_sources_support         = "disable"
      tags = {
        Purpose = "media-streaming"
        Type    = "video-distribution"
      }
    }
  }

  tags = {
    Environment = "production"
    Multicast   = "enabled"
    UseCase     = "media-streaming"
  }
}

# ============================================================================
# EXAMPLE 9: DISASTER RECOVERY TRANSIT GATEWAY
# ============================================================================
# Transit Gateway configuration for disaster recovery
# Includes backup region connectivity and failover routing

module "dr_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "dr-tgw"
  environment = "prod"
  description = "Disaster Recovery Transit Gateway with backup connectivity"

  # DR-optimized configuration
  amazon_side_asn                     = 64512
  dns_support                        = "enable"
  vpn_ecmp_support                   = "enable"
  default_route_table_association     = "disable"
  default_route_table_propagation     = "disable"

  # Primary and DR VPC attachments
  vpc_attachments = {
    primary_app = {
      vpc_id     = module.primary_app_vpc.vpc_id
      subnet_ids = module.primary_app_vpc.private_subnet_ids
      tags = {
        Environment = "production"
        Type        = "primary"
        Tier        = "application"
      }
    }
    dr_app = {
      vpc_id     = module.dr_app_vpc.vpc_id
      subnet_ids = module.dr_app_vpc.private_subnet_ids
      tags = {
        Environment = "production"
        Type        = "disaster-recovery"
        Tier        = "application"
      }
    }
    backup_services = {
      vpc_id     = module.backup_vpc.vpc_id
      subnet_ids = module.backup_vpc.private_subnet_ids
      tags = {
        Environment = "production"
        Type        = "backup"
        Tier        = "services"
      }
    }
  }

  # DR-specific route tables
  route_tables = {
    primary_active = {
      tags = {
        Purpose = "primary-routing"
        State   = "active"
      }
    }
    dr_standby = {
      tags = {
        Purpose = "dr-routing"
        State   = "standby"
      }
    }
    backup = {
      tags = {
        Purpose = "backup-routing"
        State   = "always-active"
      }
    }
  }

  # Cross-region peering for DR
  peering_attachments = {
    dr_region_peering = {
      peer_account_id         = data.aws_caller_identity.current.account_id
      peer_region            = "us-east-1"
      peer_transit_gateway_id = "tgw-dr123456789abcdef"
      tags = {
        Purpose = "disaster-recovery"
        Type    = "cross-region-backup"
      }
    }
  }

  tags = {
    Environment = "production"
    Purpose     = "disaster-recovery"
    Criticality = "business-critical"
    RTO         = "4-hours"
    RPO         = "1-hour"
  }
}