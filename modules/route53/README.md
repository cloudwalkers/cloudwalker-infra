# AWS Route 53 Module

This Terraform module creates and manages AWS Route 53 resources for comprehensive DNS management including hosted zones, DNS records, health checks, and resolver configurations.

## Features

- **Hosted Zones**: Public and private DNS zones with VPC associations
- **DNS Records**: Support for all record types (A, AAAA, CNAME, MX, TXT, SRV, etc.)
- **Advanced Routing**: Weighted, latency-based, geolocation, and failover routing policies
- **Health Checks**: HTTP/HTTPS/TCP health monitoring with CloudWatch integration
- **DNS Resolver**: Hybrid cloud DNS resolution with forwarding rules
- **Traffic Policies**: Complex routing logic with multiple conditions
- **Query Logging**: DNS query monitoring and analysis
- **Alias Records**: Integration with AWS services (ALB, CloudFront, S3, etc.)
- **Cross-Account Support**: Multi-account DNS architecture

## DNS Record Types Supported

### Standard Record Types
- **A**: IPv4 address records
- **AAAA**: IPv6 address records
- **CNAME**: Canonical name records
- **MX**: Mail exchange records
- **TXT**: Text records (SPF, DKIM, domain verification)
- **SRV**: Service records
- **NS**: Name server records
- **PTR**: Pointer records (reverse DNS)

### AWS Alias Records
- **Application Load Balancer (ALB)**
- **Network Load Balancer (NLB)**
- **CloudFront Distributions**
- **S3 Website Endpoints**
- **API Gateway**
- **Elastic Beanstalk**

## Routing Policies

### Simple Routing
Standard DNS resolution with single resource

### Weighted Routing
Distribute traffic across multiple resources based on assigned weights
- **Use Case**: Blue-green deployments, A/B testing, gradual rollouts

### Latency-Based Routing
Route traffic to the resource with lowest latency
- **Use Case**: Global applications, performance optimization

### Geolocation Routing
Route traffic based on user's geographic location
- **Use Case**: Content localization, compliance requirements

### Failover Routing
Automatic failover between primary and secondary resources
- **Use Case**: High availability, disaster recovery

### Multivalue Answer Routing
Return multiple healthy resources in response
- **Use Case**: Load distribution, redundancy

## Usage Examples

### Basic Public Hosted Zone

```hcl
module "basic_dns" {
  source = "./modules/route53"

  environment = "prod"

  public_hosted_zones = {
    main_domain = {
      domain_name = "example.com"
      comment     = "Main company domain"
    }
  }

  dns_records = {
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

    www_cname = {
      zone_name = "main_domain"
      name      = "www.example.com"
      type      = "CNAME"
      ttl       = 300
      records   = ["example.com"]
    }

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
  }

  tags = {
    Project = "CompanyWebsite"
  }
}
```

### High Availability with Health Checks

```hcl
module "ha_dns" {
  source = "./modules/route53"

  environment = "prod"

  public_hosted_zones = {
    ha_domain = {
      domain_name = "ha-app.com"
      comment     = "High availability application"
    }
  }

  health_checks = {
    primary_health = {
      type              = "HTTPS"
      fqdn              = "primary.ha-app.com"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
      measure_latency   = true
    }

    secondary_health = {
      type              = "HTTPS"
      fqdn              = "secondary.ha-app.com"
      port              = 443
      resource_path     = "/health"
      request_interval  = 30
      failure_threshold = 3
      measure_latency   = true
    }
  }

  dns_records = {
    primary_failover = {
      zone_name = "ha_domain"
      name      = "api.ha-app.com"
      type      = "A"
      ttl       = 60
      records   = ["203.0.113.10"]
      
      failover_routing_policy = {
        type = "PRIMARY"
      }
      
      health_check_id = "primary_health"
      set_identifier  = "primary"
    }

    secondary_failover = {
      zone_name = "ha_domain"
      name      = "api.ha-app.com"
      type      = "A"
      ttl       = 60
      records   = ["203.0.113.20"]
      
      failover_routing_policy = {
        type = "SECONDARY"
      }
      
      health_check_id = "secondary_health"
      set_identifier  = "secondary"
    }
  }

  tags = {
    Architecture = "high-availability"
  }
}
```

### Global Application with Geolocation Routing

```hcl
module "global_dns" {
  source = "./modules/route53"

  environment = "prod"

  public_hosted_zones = {
    global_app = {
      domain_name = "global-app.com"
      comment     = "Global application with regional routing"
    }
  }

  dns_records = {
    us_geolocation = {
      zone_name = "global_app"
      name      = "api.global-app.com"
      type      = "A"
      alias = {
        name                   = module.us_alb.dns_name
        zone_id                = module.us_alb.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {
        continent = "NA"
      }
      
      set_identifier = "north-america"
    }

    eu_geolocation = {
      zone_name = "global_app"
      name      = "api.global-app.com"
      type      = "A"
      alias = {
        name                   = module.eu_alb.dns_name
        zone_id                = module.eu_alb.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {
        continent = "EU"
      }
      
      set_identifier = "europe"
    }

    default_geolocation = {
      zone_name = "global_app"
      name      = "api.global-app.com"
      type      = "A"
      alias = {
        name                   = module.us_alb.dns_name
        zone_id                = module.us_alb.zone_id
        evaluate_target_health = true
      }
      
      geolocation_routing_policy = {}
      
      set_identifier = "default"
    }
  }

  tags = {
    Architecture = "global"
  }
}
```

### Private DNS for VPC Resources

```hcl
module "private_dns" {
  source = "./modules/route53"

  environment = "prod"

  private_hosted_zones = {
    internal_services = {
      domain_name = "internal.company.local"
      comment     = "Internal services DNS"
      vpc_associations = [
        {
          vpc_id     = module.main_vpc.vpc_id
          vpc_region = "us-west-2"
        }
      ]
    }
  }

  dns_records = {
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

    database = {
      zone_name = "internal_services"
      name      = "db.internal.company.local"
      type      = "CNAME"
      ttl       = 300
      records   = [module.rds.endpoint]
    }
  }

  tags = {
    Network = "private"
  }
}
```

### Weighted Routing for Blue-Green Deployment

```hcl
module "blue_green_dns" {
  source = "./modules/route53"

  environment = "prod"

  public_hosted_zones = {
    app_domain = {
      domain_name = "myapp.com"
      comment     = "Blue-green deployment domain"
    }
  }

  dns_records = {
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
      
      set_identifier = "blue-environment"
    }

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
      
      set_identifier = "green-environment"
    }
  }

  tags = {
    Deployment = "blue-green"
  }
}
```

### Hybrid DNS with Resolver Rules

```hcl
module "hybrid_dns" {
  source = "./modules/route53"

  environment = "prod"

  resolver_endpoints = {
    outbound = {
      main_outbound = {
        name               = "main-outbound-resolver"
        security_group_ids = [module.resolver_sg.security_group_id]
        ip_addresses = [
          {
            subnet_id = module.vpc.private_subnet_ids[0]
          },
          {
            subnet_id = module.vpc.private_subnet_ids[1]
          }
        ]
      }
    }
  }

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
        }
      ]
    }
  }

  resolver_rule_associations = {
    main_vpc_association = {
      resolver_rule_name = "on_premises_forward"
      vpc_id             = module.vpc.vpc_id
    }
  }

  tags = {
    Architecture = "hybrid"
  }
}
```

## Input Variables

### General Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment` | `string` | `"dev"` | Environment name for tagging |
| `tags` | `map(string)` | `{}` | Additional tags for resources |

### Hosted Zones

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_hosted_zones` | `bool` | `true` | Whether to create new hosted zones |
| `public_hosted_zones` | `map(object)` | `{}` | Public hosted zones to create |
| `private_hosted_zones` | `map(object)` | `{}` | Private hosted zones to create |
| `use_existing_hosted_zones` | `map(object)` | `{}` | Reference to existing hosted zones |

### DNS Records

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dns_records` | `map(object)` | `{}` | DNS records to create |

### Health Checks

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `health_checks` | `map(object)` | `{}` | Health checks to create |

### Resolver Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resolver_rules` | `map(object)` | `{}` | Resolver rules for DNS forwarding |
| `resolver_rule_associations` | `map(object)` | `{}` | VPC associations for resolver rules |
| `resolver_endpoints` | `object` | `{}` | Inbound and outbound resolver endpoints |

### Monitoring and Logging

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `query_logging_configs` | `map(object)` | `{}` | DNS query logging configurations |

## Outputs

### Hosted Zone Information

| Output | Description |
|--------|-------------|
| `public_hosted_zone_ids` | Map of public hosted zone names to IDs |
| `public_hosted_zone_name_servers` | Map of public hosted zone names to name servers |
| `private_hosted_zone_ids` | Map of private hosted zone names to IDs |
| `all_hosted_zone_ids` | Map of all hosted zone names to IDs |

### DNS Record Information

| Output | Description |
|--------|-------------|
| `dns_record_names` | Map of DNS record keys to FQDNs |
| `dns_record_types` | Map of DNS record keys to types |

### Health Check Information

| Output | Description |
|--------|-------------|
| `health_check_ids` | Map of health check names to IDs |
| `health_check_arns` | Map of health check names to ARNs |

### Resolver Information

| Output | Description |
|--------|-------------|
| `resolver_rule_ids` | Map of resolver rule names to IDs |
| `resolver_endpoint_ids` | Map of resolver endpoint names to IDs |
| `resolver_endpoint_ips` | Map of resolver endpoint names to IP addresses |

### Summary Information

| Output | Description |
|--------|-------------|
| `route53_summary` | Complete summary of all Route 53 resources |
| `domain_configurations` | Detailed domain configuration information |

## Best Practices

### DNS Design
- **Use consistent naming conventions** for subdomains and services
- **Implement proper TTL values** based on change frequency
- **Plan domain hierarchy** for scalability and organization
- **Use alias records** for AWS resources when possible

### High Availability
- **Implement health checks** for critical endpoints
- **Use failover routing** for disaster recovery
- **Deploy across multiple regions** for global applications
- **Monitor DNS resolution** with CloudWatch metrics

### Security
- **Use private hosted zones** for internal resources
- **Implement proper access controls** with IAM policies
- **Enable query logging** for security monitoring
- **Validate DNS configurations** regularly

### Performance
- **Use geolocation routing** for global applications
- **Implement latency-based routing** for performance optimization
- **Optimize TTL values** for caching efficiency
- **Use CloudFront** with Route 53 for content delivery

### Cost Optimization
- **Use alias records** instead of CNAME records for AWS resources
- **Optimize health check frequency** based on requirements
- **Monitor query volumes** and costs
- **Clean up unused DNS records** and health checks

## Integration Examples

### With Application Load Balancer

```hcl
resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnet_ids
}

module "dns" {
  source = "./modules/route53"

  dns_records = {
    app_alias = {
      zone_name = "main_domain"
      name      = "app.example.com"
      type      = "A"
      alias = {
        name                   = aws_lb.main.dns_name
        zone_id                = aws_lb.main.zone_id
        evaluate_target_health = true
      }
    }
  }
}
```

### With CloudFront Distribution

```hcl
resource "aws_cloudfront_distribution" "main" {
  # CloudFront configuration
}

module "dns" {
  source = "./modules/route53"

  dns_records = {
    cdn_alias = {
      zone_name = "main_domain"
      name      = "cdn.example.com"
      type      = "A"
      alias = {
        name                   = aws_cloudfront_distribution.main.domain_name
        zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
        evaluate_target_health = false
      }
    }
  }
}
```

### With Certificate Manager

```hcl
resource "aws_acm_certificate" "main" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = module.dns.public_hosted_zone_ids["main_domain"]
}
```

## Troubleshooting

### Common Issues

1. **DNS Propagation Delays**
   - Check TTL values and wait for propagation
   - Use DNS lookup tools to verify changes
   - Consider using lower TTL during changes

2. **Health Check Failures**
   - Verify endpoint accessibility and response codes
   - Check security group and network ACL rules
   - Review health check configuration parameters

3. **Alias Record Issues**
   - Ensure correct zone ID for AWS resources
   - Verify resource exists and is accessible
   - Check evaluate_target_health setting

4. **Private Zone Resolution**
   - Verify VPC DNS settings (enableDnsHostnames, enableDnsSupport)
   - Check VPC associations for private zones
   - Ensure resolver rules are properly configured

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |

## Resources Created

- `aws_route53_zone` - Public and private hosted zones
- `aws_route53_record` - DNS records with various routing policies
- `aws_route53_health_check` - Health checks for monitoring
- `aws_route53_resolver_rule` - DNS forwarding rules
- `aws_route53_resolver_endpoint` - Inbound and outbound resolver endpoints
- `aws_route53_resolver_rule_association` - VPC associations for resolver rules
- `aws_route53_zone_association` - Additional VPC associations
- `aws_route53_delegation_set` - Reusable delegation sets
- `aws_route53_query_log` - Query logging configurations
- `aws_cloudwatch_log_group` - Log groups for query logs
- `aws_route53_traffic_policy` - Traffic policies for complex routing
- `aws_route53_traffic_policy_instance` - Traffic policy instances

## License

This module is released under the MIT License.