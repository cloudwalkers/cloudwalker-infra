# ELB (Elastic Load Balancer) Module

This module creates AWS Elastic Load Balancers (Application Load Balancer, Network Load Balancer, or Gateway Load Balancer) with comprehensive configuration options.

## Features

- **Multiple Load Balancer Types**: Application, Network, and Gateway Load Balancers
- **Flexible Target Groups**: Support for instance, IP, and Lambda targets
- **Advanced Routing**: Path-based, host-based, and header-based routing rules
- **SSL/TLS Support**: HTTPS listeners with certificate management
- **Health Checks**: Configurable health check parameters
- **Sticky Sessions**: Session affinity configuration
- **Access Logs**: S3 access logging support
- **Security Groups**: Automatic security group creation for ALBs
- **Cross-Zone Load Balancing**: Enhanced availability options

## Usage

### Basic Application Load Balancer

```hcl
module "web_alb" {
  source = "./modules/elb"

  name       = "web-app-alb"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_groups = {
    "web-servers" = {
      port     = 80
      protocol = "HTTP"
      health_check = {
        path    = "/health"
        matcher = "200"
      }
    }
  }

  listener_rules = {
    "http" = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type              = "forward"
        target_group_name = "web-servers"
      }
    }
  }

  tags = {
    Environment = "production"
  }
}
```

### HTTPS with HTTP Redirect

```hcl
module "secure_alb" {
  source = "./modules/elb"

  name       = "secure-app-alb"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_groups = {
    "app-servers" = {
      port     = 8080
      protocol = "HTTP"
    }
  }

  listener_rules = {
    "http" = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
    "https" = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
      default_action = {
        type              = "forward"
        target_group_name = "app-servers"
      }
    }
  }
}
```

### Path-Based Routing

```hcl
module "microservices_alb" {
  source = "./modules/elb"

  name       = "microservices-alb"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_groups = {
    "frontend" = {
      port     = 80
      protocol = "HTTP"
    }
    "api" = {
      port     = 8080
      protocol = "HTTP"
    }
  }

  listener_rules = {
    "http" = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type              = "forward"
        target_group_name = "frontend"
      }
    }
  }

  listener_rules_additional = {
    "api-routing" = {
      listener_key = "http"
      priority     = 100
      action = {
        type              = "forward"
        target_group_name = "api"
      }
      conditions = [
        {
          field  = "path-pattern"
          values = ["/api/*"]
        }
      ]
    }
  }
}
```

### Network Load Balancer

```hcl
module "tcp_nlb" {
  source = "./modules/elb"

  name               = "tcp-service-nlb"
  load_balancer_type = "network"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids

  target_groups = {
    "tcp-servers" = {
      port        = 8080
      protocol    = "TCP"
      target_type = "instance"
    }
  }

  listener_rules = {
    "tcp" = {
      port     = 80
      protocol = "TCP"
      default_action = {
        type              = "forward"
        target_group_name = "tcp-servers"
      }
    }
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the load balancer | `string` | n/a | yes |
| vpc_id | VPC ID where the load balancer will be created | `string` | n/a | yes |
| subnet_ids | List of subnet IDs to attach to the load balancer | `list(string)` | n/a | yes |
| load_balancer_type | Type of load balancer (application, network, gateway) | `string` | `"application"` | no |
| internal | Whether the load balancer is internal | `bool` | `false` | no |
| target_groups | Map of target group configurations | `map(object)` | `{}` | no |
| listener_rules | Map of listener configurations | `map(object)` | `{}` | no |
| listener_rules_additional | Additional listener rules for routing | `map(object)` | `{}` | no |
| target_group_attachments | Map of target group attachments | `map(object)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| load_balancer_arn | ARN of the load balancer |
| load_balancer_dns_name | DNS name of the load balancer |
| load_balancer_zone_id | Hosted zone ID for Route53 alias records |
| target_group_arns | ARNs of the target groups |
| listener_arns | ARNs of the listeners |
| security_group_id | ID of the load balancer security group (ALB only) |

## Target Group Configuration

Target groups support various configuration options:

```hcl
target_groups = {
  "my-targets" = {
    port                         = 80
    protocol                     = "HTTP"
    target_type                  = "instance"  # instance, ip, lambda
    deregistration_delay         = 300
    slow_start                   = 0
    load_balancing_algorithm_type = "round_robin"  # round_robin, least_outstanding_requests
    
    health_check = {
      enabled             = true
      healthy_threshold   = 3
      unhealthy_threshold = 3
      timeout             = 5
      interval            = 30
      path                = "/"
      matcher             = "200"
      port                = "traffic-port"
      protocol            = "HTTP"
    }
    
    stickiness = {
      type            = "lb_cookie"
      cookie_duration = 86400
      enabled         = true
    }
  }
}
```

## Listener Rules and Conditions

The module supports various routing conditions:

- **Path Pattern**: Route based on URL path
- **Host Header**: Route based on hostname
- **HTTP Header**: Route based on custom headers
- **Query String**: Route based on query parameters

## Best Practices

1. **High Availability**: Always use at least 2 subnets in different AZs
2. **Security**: Use internal load balancers for internal services
3. **SSL/TLS**: Always use HTTPS for production applications
4. **Health Checks**: Configure appropriate health check paths
5. **Monitoring**: Enable access logs for troubleshooting
6. **Tagging**: Use consistent tagging for resource management

## Examples

See `examples.tf` for comprehensive usage examples including:
- Simple HTTP ALB
- HTTPS with redirect
- Multi-service routing
- Network Load Balancer