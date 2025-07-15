# Example 1: Basic Auto Scaling Group
/*
module "basic_asg" {
  source = "./modules/ec2"

  name_prefix       = "web-app"
  ami_id           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type    = "t3.micro"
  key_name         = "my-web-key"

  # Networking
  subnet_ids        = ["subnet-12345678", "subnet-87654321"]
  security_group_ids = ["sg-12345678"]

  # Basic scaling
  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
*/

# Example 2: Development Environment with Cost Optimization
/*
module "dev_environment" {
  source = "./modules/ec2"

  name_prefix       = "dev-api"
  ami_id           = "ami-0c55b159cbfafe1f0"
  instance_type    = "t2.micro"  # Free tier eligible
  key_name         = "dev-team-key"

  # Networking
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.dev_api.id]

  # Minimal scaling for cost savings
  desired_capacity = 1
  min_size         = 1
  max_size         = 2

  # Basic health check
  health_check_type = "EC2"

  tags = {
    Environment  = "development"
    Team         = "backend"
    AutoShutdown = "enabled"
    CostCenter   = "engineering"
  }
}
*/

# Example 3: Production API with Load Balancer Integration
/*
# First create the load balancer
module "api_alb" {
  source = "./modules/elb"

  name       = "api-alb"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  target_groups = {
    "api-servers" = {
      port     = 8080
      protocol = "HTTP"
      health_check = {
        path    = "/api/v1/health"
        port    = "8080"
        matcher = "200"
      }
    }
  }

  listener_rules = {
    "https" = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:region:account:certificate/cert-id"
      default_action = {
        type              = "forward"
        target_group_name = "api-servers"
      }
    }
  }
}

# Then create the EC2 instances
module "production_api" {
  source = "./modules/ec2"

  name_prefix       = "prod-api"
  ami_id           = "ami-0c55b159cbfafe1f0"
  instance_type    = "t3.medium"
  key_name         = "prod-api-key"

  # Networking
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.api.id]

  # High availability configuration
  desired_capacity = 6
  min_size         = 3
  max_size         = 12

  # Load balancer integration
  target_group_arns = [module.api_alb.target_group_arns["api-servers"]]
  health_check_type = "ELB"

  # Enable auto scaling
  enable_scaling_policies = true
  cpu_high_threshold     = 70
  cpu_low_threshold      = 30

  tags = {
    Environment = "production"
    Application = "api-service"
    Team        = "backend"
    Criticality = "high"
    Monitoring  = "enabled"
    Backup      = "required"
  }
}
*/

# Example 4: Advanced Configuration with Custom Storage and User Data
/*
module "advanced_app" {
  source = "./modules/ec2"

  name_prefix       = "advanced-app"
  ami_id           = "ami-0c55b159cbfafe1f0"
  instance_type    = "t3.medium"
  key_name         = "app-key"

  # Networking
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.app.id]

  # Custom storage configuration
  block_device_mappings = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    },
    {
      device_name           = "/dev/xvdf"
      volume_size           = 100
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = false
    }
  ]

  # IAM and initialization
  iam_instance_profile_name = aws_iam_instance_profile.app.name
  user_data_base64         = base64encode(templatefile("${path.module}/user-data.sh", {
    app_version = "v1.2.3"
    environment = "staging"
  }))

  # Scaling configuration
  desired_capacity = 3
  min_size         = 2
  max_size         = 6

  # Instance refresh for zero-downtime updates
  enable_instance_refresh = true
  instance_refresh_min_healthy_percentage = 90

  tags = {
    Environment = "staging"
    Application = "advanced-app"
    Purpose     = "integration-testing"
    Team        = "platform"
  }
}
*/

# Example 5: Multi-Environment Setup
/*
# Production Environment
module "prod_web" {
  source = "./modules/ec2"

  name_prefix       = "prod-web"
  ami_id           = "ami-0c55b159cbfafe1f0"
  instance_type    = "t3.large"
  key_name         = "prod-web-key"

  # Networking
  subnet_ids        = module.prod_vpc.private_subnet_ids
  security_group_ids = [aws_security_group.prod_web.id]

  # High availability scaling
  desired_capacity = 8
  min_size         = 4
  max_size         = 16

  # Production-grade features
  enable_scaling_policies = true
  enable_instance_refresh = true
  health_check_type      = "ELB"
  target_group_arns      = [module.prod_alb.target_group_arns["web-servers"]]

  tags = {
    Environment = "production"
    Application = "website"
    Team        = "frontend"
    Criticality = "high"
  }
}

# Staging Environment
module "staging_web" {
  source = "./modules/ec2"

  name_prefix       = "staging-web"
  ami_id           = "ami-0c55b159cbfafe1f0"
  instance_type    = "t3.medium"
  key_name         = "staging-web-key"

  # Networking
  subnet_ids        = module.staging_vpc.private_subnet_ids
  security_group_ids = [aws_security_group.staging_web.id]

  # Moderate scaling for testing
  desired_capacity = 4
  min_size         = 2
  max_size         = 8

  # Basic features for staging
  health_check_type = "ELB"
  target_group_arns = [module.staging_alb.target_group_arns["web-servers"]]

  tags = {
    Environment = "staging"
    Application = "website"
    Team        = "frontend"
    Purpose     = "testing"
  }
}
*/

# Example 6: High-Performance Computing with Auto Scaling
/*
module "compute_cluster" {
  source = "./modules/ec2"

  name_prefix       = "compute-cluster"
  ami_id           = "ami-custom123456"  # Custom AMI with pre-installed software
  instance_type    = "c5.xlarge"        # Compute-optimized
  key_name         = "compute-key"

  # Networking
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.compute.id]

  # High-performance storage
  block_device_mappings = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 100
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    },
    {
      device_name           = "/dev/xvdf"
      volume_size           = 500
      volume_type           = "io2"
      encrypted             = true
      delete_on_termination = false
    }
  ]

  # IAM role for compute tasks
  iam_instance_profile_name = aws_iam_instance_profile.compute.name

  # Scaling configuration
  desired_capacity = 4
  min_size         = 2
  max_size         = 20

  # Aggressive auto scaling for compute workloads
  enable_scaling_policies = true
  cpu_high_threshold     = 60
  cpu_low_threshold      = 10
  scale_up_adjustment    = 2
  scale_down_adjustment  = -1

  # Fast scaling
  scale_up_cooldown   = 180
  scale_down_cooldown = 300

  tags = {
    Environment   = "production"
    Application   = "compute-cluster"
    Workload      = "high-performance-computing"
    InstanceClass = "compute-optimized"
  }
}
*/# Ex
ample 7: Complete Integration with ELB, Route53, and VPC Modules
/*
# VPC Infrastructure
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix             = "myapp"
  vpc_cidr_block          = "10.0.0.0/16"
  public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
}

# Application Load Balancer
module "alb" {
  source = "./modules/elb"
  
  name       = "myapp-alb"
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
}

# Security Group for EC2 instances
resource "aws_security_group" "web_servers" {
  name_prefix = "web-servers-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Auto Scaling Group
module "web_servers" {
  source = "./modules/ec2"
  
  name_prefix       = "myapp-web"
  ami_id           = "ami-0c55b159cbfafe1f0"
  instance_type    = "t3.medium"
  key_name         = "myapp-key"
  
  # Networking
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.web_servers.id]
  
  # Load balancer integration
  target_group_arns = [module.alb.target_group_arns["web-servers"]]
  health_check_type = "ELB"
  
  # Auto scaling configuration
  desired_capacity = 3
  min_size         = 2
  max_size         = 8
  
  # Enable intelligent scaling
  enable_scaling_policies = true
  cpu_high_threshold     = 75
  cpu_low_threshold      = 25
  
  # Zero-downtime deployments
  enable_instance_refresh = true
  
  tags = {
    Environment = "production"
    Application = "web-app"
    Tier        = "web"
  }
}

# Route53 DNS (if using Route53 module)
module "dns" {
  source = "./modules/route53"
  
  domain_name = "myapp.example.com"
  
  records = [
    {
      name = "www"
      type = "A"
      alias = {
        name    = module.alb.load_balancer_dns_name
        zone_id = module.alb.load_balancer_zone_id
      }
    }
  ]
}
*/