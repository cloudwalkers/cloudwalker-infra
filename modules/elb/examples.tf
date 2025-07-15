# Example 1: Simple HTTP Application Load Balancer
/*
module "simple_alb" {
  source = "./modules/elb"

  name       = "my-app-alb"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  target_groups = {
    "web-servers" = {
      port     = 80
      protocol = "HTTP"
      health_check = {
        path                = "/health"
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 5
        interval            = 30
        matcher             = "200"
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

  target_group_attachments = {
    "web-1" = {
      target_group_name = "web-servers"
      target_id         = "i-1234567890abcdef0"
      port              = 80
    }
    "web-2" = {
      target_group_name = "web-servers"
      target_id         = "i-0987654321fedcba0"
      port              = 80
    }
  }

  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
*/

# Example 2: HTTPS ALB with HTTP to HTTPS redirect
/*
module "https_alb" {
  source = "./modules/elb"

  name       = "secure-app-alb"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  target_groups = {
    "api-servers" = {
      port     = 8080
      protocol = "HTTP"
      health_check = {
        path     = "/api/health"
        port     = "8080"
        protocol = "HTTP"
        matcher  = "200"
      }
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
      certificate_arn = "arn:aws:acm:us-west-2:123456789012:certificate/12345678-1234-1234-1234-123456789012"
      default_action = {
        type              = "forward"
        target_group_name = "api-servers"
      }
    }
  }

  tags = {
    Environment = "production"
    Application = "api"
  }
}
*/

# Example 3: ALB with path-based routing
/*
module "multi_service_alb" {
  source = "./modules/elb"

  name       = "multi-service-alb"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-87654321"]

  target_groups = {
    "frontend" = {
      port     = 80
      protocol = "HTTP"
    }
    "api" = {
      port     = 8080
      protocol = "HTTP"
    }
    "admin" = {
      port     = 9090
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
    "api-path" = {
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
    "admin-path" = {
      listener_key = "http"
      priority     = 200
      action = {
        type              = "forward"
        target_group_name = "admin"
      }
      conditions = [
        {
          field  = "path-pattern"
          values = ["/admin/*"]
        }
      ]
    }
  }

  tags = {
    Environment = "production"
    Application = "multi-service"
  }
}
*/

# Example 4: Network Load Balancer
/*
module "network_lb" {
  source = "./modules/elb"

  name               = "tcp-nlb"
  load_balancer_type = "network"
  vpc_id             = "vpc-12345678"
  subnet_ids         = ["subnet-12345678", "subnet-87654321"]

  target_groups = {
    "tcp-servers" = {
      port        = 8080
      protocol    = "TCP"
      target_type = "instance"
      health_check = {
        protocol = "TCP"
        port     = "8080"
      }
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

  tags = {
    Environment = "production"
    Protocol    = "tcp"
  }
}
*/