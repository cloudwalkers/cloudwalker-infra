# ============================================================================
# AWS ROUTE 53 MODULE USAGE EXAMPLES
# ============================================================================
# Comprehensive examples showing different Route 53 configurations
# These examples demonstrate various use cases and best practices
# ============================================================================

# ============================================================================
# EXAMPLE 1: BASIC PUBLIC HOSTED ZONE WITH DNS RECORDS
# ============================================================================
# Simple public hosted zone for a domain with basic DNS records
# Suitable for most standard website and application scenarios

module "basic_public_dns" {
  source = "./modules/route53"

  environment = "prod"

  # Create public hosted zone
  public_hosted_zones = {
    main_domain = {
      domain_name = "example.com"
      comment     = "Main domain for Example Company"
      tags = {
        Domain  = "example.com"
        Purpose = "primary-website"
      }
    }
  }

  # Basic DNS records
  dns_records = {
    # Root domain A record pointing to load balancer
    root_a = {
      zone_name = "main_domain"
      name      = "example.com"
      type      = "A"
      alias = {
        name                   = module.alb.dns_name
        zone_id                = module.alb.zone_id
        evaluate_target_health = true
      }
    }

    # WWW subdomain CNAME
    www_cname = {
      zone_name = "main_domain"
      name      = "www.example.com"
      type      = "CNAME"
      ttl       = 300
      records   = ["example.com"]
    }

    # MX record for email
    mx_record = {
      zone_name = "main_domain"
      name      = "example.com"
      type      = "MX"
      ttl       = 300
      records   = [
        "10 mail.example.com",
        "20 mail2.example.com"
      ]
    }

    # TXT record for domain verification
    txt_verification = {
      zone_name = "main_domain"
      name      = "example.com"
      type      = "TXT"
      ttl       = 300
      records   = [
        "v=spf1 include:_spf.google.com ~all",
        "google-site-verification=abc123def456"
      ]
    }
  }

  tags = {
    Project = "CompanyWebsite"
    Owner   = "DevOps"
  }
}

# ============================================================================
# EXAMPLE 2: MULTI-ENVIRONMENT DNS WITH SUBDOMAINS
# ============================================================================
# DNS setup for multiple environments using subdomains
# Demonstrates environment-specific DNS management

module "multi_environment_dns" {
  source = "./modules/route53"

  environment = "multi-env"

  # Main domain hosted zone
  public_hosted_zones = {
    main_domain = {
      domain_name = "mycompany.com"
      comment     = "Main company domain"
    }
  }

  # Environment-specific DNS records
  dns_records = {
    # Production environment
    prod_api = {
      zone_name = "main_domain"
      name      = "api.mycompany.com"
      type      = "A"
      alias = {
        name                   = module.prod_alb.dns_name
        zone_id                = module.prod_alb.zone_id
        evaluate_target_health = true
      }
    }

    prod_app = {
      zone_name = "main_domain"
      name      = "app.mycompany.com"
      type      = "A"
      alias = {
        name                   = module.prod_cloudfront.domain_name
        zone_id                = module.prod_cloudfront.hosted_zone_id
        evaluate_target_health = false
      }
    }

    # Staging environment
    staging_api = {
      zone_name = "main_domain"
      name      = "staging-api.mycompany.com"
      type      = "A"
      alias = {
        name                   = module.staging_alb.dns_name
        zone_id                = module.staging_alb.zone_id
        evaluate_target_health = true
      }
    }

    staging_app = {
      zone_name = "main_domain"
      name      = "staging.mycompany.com"
      type      = "A"
      alias = {
        name                   = module.staging_alb.dns_name
        zone_id                = module.staging_alb.zone_id
        evaluate_target_health = true
      }
    }

    # Development environment
    dev_api = {
      zone_name = "main_domain"
      name      = "dev-api.mycompany.com"
      type      = "A"
      ttl       = 300
      records   = [module.dev_instance.public_ip]
    }
  }

  tags = {
    Architecture = "multi-environment"
    DNS          = "centralized"
  }
}

# ============================================================================
# EXAMPLE 3: HIGH AVAILABILITY DNS WITH HEALTH CHECKS
# ============================================================================
# DNS failover configuration with health checks
# Provides automatic failover between primary and secondary resources

module "ha_dns_with_failover" {
  source = "./modules/route53"

  environment = "prod"

  public_hosted_zones = {
    ha_domain = {
      domain_name = "ha-app.com"
      comment     = "High availability application domain"
    }
  }

  # Health checks for failover
  health_checks = {
    primary_health_check = {
      type                     = "HTTPS"
      fqdn                     = "primary.ha-app.com"
      port                     = 443
      resource_path            = "/health"
      request_interval         = 30
      failure_threshold        = 3
      measure_latency          = true
      enable_sni               = true
      tags = {
        Purpose = "primary-endpoint-monitoring"
      }
    }

    secondary_health_check = {
      type                     = "HTTPS"
      fqdn                     = "secondary.ha-app.com"
      port                     = 443
      resource_path            = "/health"
      request_interval         = 30
      failure_threshold        = 3
      measure_latency          = true
      enable_sni               = true
      tags = {
        Purpose = "secondary-endpoint-monitoring"
      }
    }
  }

  # Failover DNS records
  dns_records = {
    # Primary record
    primary_failover = {
      zone_name = "ha_domain"
      name      = "api.ha-app.com"
      type      = "A"
      ttl       = 60
      records   = ["203.0.113.10"]
      
      failover_routing_policy = {
        type = "PRIMARY"
      }
      
      health_check_id = "primary_health_check"
      set_identifier  = "primary"
    }

    # Secondary record
    secondary_failover = {
      zone_name = "ha_domain"
      name      = "api.ha-app.com"
      type      = "A"
      ttl       = 60
      records   = ["203.0.113.20"]
      
      failover_routing_policy = {
        type = "SECONDARY"
      }
      
      health_check_id = "secondary_health_check"
      set_identifier  = "secondary"
    }
  }

  tags = {
    Architecture = "high-availability"
    Failover     = "enabled"
  }
}

# ============================================================================
# EXAMPLE 4: GEOLOCATION-BASED ROUTING
# ============================================================================
# DNS routing based on geographic location
# Directs users to the nearest regional endpoint

module "global_dns_routing" {
  source = "./modules/route53"

  environment = "prod"

  public_hosted_zones = {
    global_app = {
      domain_name = "global-app.com"
      comment     = "Global application with regional routing"
    }
  }

  # Health checks for regional endpoints
  health_checks = {
    us_east_health = {
      type              = "HTTPS"
      fqdn              = "us-east.global-app.com"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
    }

    eu_west_health = {
      type              = "HTTPS"
      fqdn              = "eu-west.global-app.com"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
    }

    ap_southeast_health = {
      type              = "HTTPS"
      fqdn              = "ap-southeast.global-app.com"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
    }
  }

  # Geolocation-based DNS records
  dns_records = {
    # North America routing
    us_geolocation = {
      zone_name = "global_app"
      name      = "api.global-app.com"
      type      = "A"
      alias = {
        name                   = module.us_east_alb.dns_name
        zone_id                = module.us_east_alb.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {
        continent = "NA"
      }
      
      health_check_id = "us_east_health"
      set_identifier  = "north-america"
    }

    # Europe routing
    eu_geolocation = {
      zone_name = "global_app"
      name      = "api.global-app.com"
      type      = "A"
      alias = {
        name                   = module.eu_west_alb.dns_name
        zone_id                = module.eu_west_alb.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {
        continent = "EU"
      }
      
      health_check_id = "eu_west_health"
      set_identifier  = "europe"
    }

    # Asia Pacific routing
    ap_geolocation = {
      zone_name = "global_app"
      name      = "api.global-app.com"
      type      = "A"
      alias = {
        name                   = module.ap_southeast_alb.dns_name
        zone_id                = module.ap_southeast_alb.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {
        continent = "AS"
      }
      
      health_check_id = "ap_southeast_health"
      set_identifier  = "asia-pacific"
    }

    # Default routing (fallback)
    default_geolocation = {
      zone_name = "global_app"
      name      = "api.global-app.com"
      type      = "A"
      alias = {
        name                   = module.us_east_alb.dns_name
        zone_id                = module.us_east_alb.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {}
      
      health_check_id = "us_east_health"
      set_identifier  = "default"
    }
  }

  tags = {
    Architecture = "global"
    Routing      = "geolocation"
  }
}

# ============================================================================
# EXAMPLE 5: PRIVATE DNS FOR VPC RESOURCES
# ============================================================================
# Private hosted zones for internal VPC DNS resolution
# Enables service discovery within VPC environments

module "private_dns" {
  source = "./modules/route53"

  environment = "prod"

  # Private hosted zones for internal services
  private_hosted_zones = {
    internal_services = {
      domain_name = "internal.company.local"
      comment     = "Internal services DNS"
      vpc_associations = [
        {
          vpc_id     = module.main_vpc.vpc_id
          vpc_region = "us-west-2"
        },
        {
          vpc_id     = module.shared_vpc.vpc_id
          vpc_region = "us-west-2"
        }
      ]
      tags = {
        Type = "internal-services"
      }
    }

    database_services = {
      domain_name = "db.company.local"
      comment     = "Database services DNS"
      vpc_associations = [
        {
          vpc_id     = module.main_vpc.vpc_id
          vpc_region = "us-west-2"
        }
      ]
      tags = {
        Type = "database-services"
      }
    }
  }

  # Internal DNS records
  dns_records = {
    # Application services
    api_internal = {
      zone_name = "internal_services"
      name      = "api.internal.company.local"
      type      = "A"
      alias = {
        name                   = module.internal_alb.dns_name
        zone_id                = module.internal_alb.zone_id
        evaluate_target_health = false
      }
    }

    cache_service = {
      zone_name = "internal_services"
      name      = "cache.internal.company.local"
      type      = "A"
      ttl       = 300
      records   = [module.elasticache.primary_endpoint]
    }

    # Database services
    primary_db = {
      zone_name = "database_services"
      name      = "primary.db.company.local"
      type      = "CNAME"
      ttl       = 300
      records   = [module.rds.endpoint]
    }

    read_replica = {
      zone_name = "database_services"
      name      = "read.db.company.local"
      type      = "CNAME"
      ttl       = 300
      records   = [module.rds.read_replica_endpoint]
    }
  }

  tags = {
    Network = "private"
    Purpose = "service-discovery"
  }
}

# ============================================================================
# EXAMPLE 6: WEIGHTED ROUTING FOR BLUE-GREEN DEPLOYMENTS
# ============================================================================
# Weighted DNS routing for gradual traffic shifting
# Supports blue-green and canary deployment strategies

module "blue_green_dns" {
  source = "./modules/route53"

  environment = "prod"

  public_hosted_zones = {
    app_domain = {
      domain_name = "myapp.com"
      comment     = "Application domain with blue-green deployment"
    }
  }

  # Health checks for both environments
  health_checks = {
    blue_health = {
      type              = "HTTPS"
      fqdn              = "blue.myapp.com"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
    }

    green_health = {
      type              = "HTTPS"
      fqdn              = "green.myapp.com"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
    }
  }

  # Weighted DNS records for blue-green deployment
  dns_records = {
    # Blue environment (90% traffic)
    blue_weighted = {
      zone_name = "app_domain"
      name      = "api.myapp.com"
      type      = "A"
      alias = {
        name                   = module.blue_alb.dns_name
        zone_id                = module.blue_alb.zone_id
        evaluate_target_health = true
      }
      
      weighted_routing_policy = {
        weight = 90
      }
      
      health_check_id = "blue_health"
      set_identifier  = "blue-environment"
    }

    # Green environment (10% traffic)
    green_weighted = {
      zone_name = "app_domain"
      name      = "api.myapp.com"
      type      = "A"
      alias = {
        name                   = module.green_alb.dns_name
        zone_id                = module.green_alb.zone_id
        evaluate_target_health = true
      }
      
      weighted_routing_policy = {
        weight = 10
      }
      
      health_check_id = "green_health"
      set_identifier  = "green-environment"
    }
  }

  tags = {
    Deployment = "blue-green"
    Strategy   = "weighted-routing"
  }
}

# ============================================================================
# EXAMPLE 7: HYBRID DNS WITH RESOLVER RULES
# ============================================================================
# DNS resolution for hybrid cloud environments
# Enables DNS forwarding between AWS and on-premises

module "hybrid_dns_resolver" {
  source = "./modules/route53"

  environment = "prod"

  # Private hosted zone for AWS resources
  private_hosted_zones = {
    aws_internal = {
      domain_name = "aws.company.internal"
      comment     = "AWS internal services"
      vpc_associations = [
        {
          vpc_id     = module.main_vpc.vpc_id
          vpc_region = "us-west-2"
        }
      ]
    }
  }

  # Resolver endpoints for hybrid connectivity
  resolver_endpoints = {
    inbound = {
      main_inbound = {
        name               = "main-inbound-resolver"
        security_group_ids = [module.resolver_sg.security_group_id]
        ip_addresses = [
          {
            subnet_id = module.main_vpc.private_subnet_ids[0]
          },
          {
            subnet_id = module.main_vpc.private_subnet_ids[1]
          }
        ]
        tags = {
          Purpose = "on-premises-to-aws"
        }
      }
    }
    
    outbound = {
      main_outbound = {
        name               = "main-outbound-resolver"
        security_group_ids = [module.resolver_sg.security_group_id]
        ip_addresses = [
          {
            subnet_id = module.main_vpc.private_subnet_ids[0]
          },
          {
            subnet_id = module.main_vpc.private_subnet_ids[1]
          }
        ]
        tags = {
          Purpose = "aws-to-on-premises"
        }
      }
    }
  }

  # Resolver rules for forwarding
  resolver_rules = {
    on_premises_forward = {
      domain_name          = "company.internal"
      name                 = "forward-to-on-premises"
      rule_type            = "FORWARD"
      resolver_endpoint_id = "main_outbound"
      target_ips = [
        {
          ip   = "10.0.100.10"
          port = 53
        },
        {
          ip   = "10.0.100.11"
          port = 53
        }
      ]
      tags = {
        Direction = "outbound"
        Target    = "on-premises"
      }
    }
  }

  # Associate resolver rules with VPCs
  resolver_rule_associations = {
    main_vpc_association = {
      resolver_rule_name = "on_premises_forward"
      vpc_id             = module.main_vpc.vpc_id
    }
  }

  tags = {
    Architecture = "hybrid"
    DNS          = "resolver-enabled"
  }
}

# ============================================================================
# EXAMPLE 8: DNS WITH QUERY LOGGING AND MONITORING
# ============================================================================
# DNS setup with comprehensive logging and monitoring
# Enables DNS query analysis and security monitoring

module "monitored_dns" {
  source = "./modules/route53"

  environment = "prod"

  public_hosted_zones = {
    monitored_domain = {
      domain_name = "monitored.com"
      comment     = "Domain with comprehensive monitoring"
    }
  }

  # Enable query logging
  query_logging_configs = {
    main_domain_logging = {
      zone_name          = "monitored_domain"
      log_retention_days = 90
    }
  }

  # Health checks with CloudWatch integration
  health_checks = {
    main_app_health = {
      type                        = "HTTPS"
      fqdn                        = "app.monitored.com"
      port                        = 443
      resource_path               = "/health"
      request_interval            = 30
      failure_threshold           = 3
      measure_latency             = true
      cloudwatch_logs_region      = "us-west-2"
      cloudwatch_logs_group_name  = "/aws/route53/health-checks"
      tags = {
        Monitoring = "enabled"
        Critical   = "true"
      }
    }
  }

  # DNS records with health checks
  dns_records = {
    main_app = {
      zone_name = "monitored_domain"
      name      = "app.monitored.com"
      type      = "A"
      alias = {
        name                   = module.app_alb.dns_name
        zone_id                = module.app_alb.zone_id
        evaluate_target_health = true
      }
      health_check_id = "main_app_health"
    }
  }

  tags = {
    Monitoring = "comprehensive"
    Logging    = "enabled"
  }
}

# ============================================================================
# EXAMPLE 9: MULTI-ACCOUNT DNS ARCHITECTURE
# ============================================================================
# DNS architecture spanning multiple AWS accounts
# Demonstrates cross-account DNS management

module "multi_account_dns" {
  source = "./modules/route53"

  environment = "prod"

  # Central DNS account hosted zone
  public_hosted_zones = {
    company_domain = {
      domain_name = "company.com"
      comment     = "Central company domain managed from DNS account"
    }
  }

  # DNS records pointing to resources in different accounts
  dns_records = {
    # Production account resources
    prod_api = {
      zone_name = "company_domain"
      name      = "api.company.com"
      type      = "A"
      alias = {
        name                   = "prod-alb-123456789.us-west-2.elb.amazonaws.com"
        zone_id                = "Z1D633PJN98FT9"  # ALB zone ID for us-west-2
        evaluate_target_health = true
      }
    }

    # Development account resources
    dev_api = {
      zone_name = "company_domain"
      name      = "dev-api.company.com"
      type      = "A"
      alias = {
        name                   = "dev-alb-987654321.us-west-2.elb.amazonaws.com"
        zone_id                = "Z1D633PJN98FT9"  # ALB zone ID for us-west-2
        evaluate_target_health = true
      }
    }

    # Shared services account resources
    shared_services = {
      zone_name = "company_domain"
      name      = "shared.company.com"
      type      = "A"
      alias = {
        name                   = "shared-alb-555666777.us-west-2.elb.amazonaws.com"
        zone_id                = "Z1D633PJN98FT9"  # ALB zone ID for us-west-2
        evaluate_target_health = true
      }
    }
  }

  tags = {
    Architecture = "multi-account"
    Management   = "centralized"
  }
}