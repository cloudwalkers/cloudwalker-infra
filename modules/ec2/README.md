# EC2 Module

This module creates optimized EC2 Auto Scaling infrastructure with Launch Templates and Auto Scaling Groups. It's designed to work seamlessly with separate ELB and Route53 modules for a modular architecture.

## Features

- **Launch Templates**: Advanced instance configuration with block device mappings
- **Auto Scaling Groups**: Intelligent scaling with health checks and policies
- **Instance Refresh**: Rolling updates for zero-downtime deployments
- **CloudWatch Integration**: CPU-based auto scaling with configurable thresholds
- **Multi-AZ Support**: Distributes instances across multiple availability zones
- **Flexible Networking**: Works with any subnet configuration (public/private)
- **IAM Integration**: Support for instance profiles and roles
- **User Data Support**: Custom initialization scripts
- **EBS Optimization**: Configurable storage with encryption

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  Launch Template                           │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  • AMI ID & Instance Type                          │    │
│  │  • Security Groups                                 │    │
│  │  • Block Device Mappings (EBS)                    │    │
│  │  • IAM Instance Profile                           │    │
│  │  • User Data Script                               │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Auto Scaling Group                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  • Min/Max/Desired Capacity                        │    │
│  │  • Health Check Type & Grace Period               │    │
│  │  • Instance Refresh Configuration                 │    │
│  │  • Termination Policies                           │    │
│  └─────────────────────────────────────────────────────┘    │
│         ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│         │  EC2-1  │  │  EC2-2  │  │  EC2-3  │              │
│         │  AZ-1a  │  │  AZ-1b  │  │  AZ-1c  │              │
│         └─────────┘  └─────────┘  └─────────┘              │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│              CloudWatch Auto Scaling                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  • CPU High/Low Alarms                            │    │
│  │  • Scale Up/Down Policies                         │    │
│  │  • Configurable Thresholds                        │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Auto Scaling Group

```hcl
module "web_servers" {
  source = "./modules/ec2"

  name_prefix       = "web-app"
  ami_id           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
  instance_type    = "t3.micro"
  key_name         = "my-key-pair"
  
  # Networking
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_ids = [module.vpc.default_security_group_id]

  # Auto Scaling Configuration
  desired_capacity = 2
  min_size         = 1
  max_size         = 5

  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
```

### With Load Balancer Integration

```hcl
# Create load balancer first
module "alb" {
  source = "./modules/elb"
  
  name       = "web-app-alb"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  
  target_groups = {
    "web-servers" = {
      port     = 80
      protocol = "HTTP"
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

# Create EC2 instances with ALB integration
module "web_servers" {
  source = "./modules/ec2"

  name_prefix       = "web-app"
  ami_id           = "ami-0c55b159cbfafe1f0"
  instance_type    = "t3.micro"
  key_name         = "my-key-pair"
  
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_ids = [module.vpc.default_security_group_id]

  # Load balancer integration
  target_group_arns = [module.alb.target_group_arns["web-servers"]]
  health_check_type = "ELB"

  desired_capacity = 3
  min_size         = 2
  max_size         = 6

  tags = {
    Environment = "production"
    Application = "web-app"
  }
}
```

### Advanced Configuration with Auto Scaling

```hcl
module "api_servers" {
  source = "./modules/ec2"

  name_prefix       = "api-service"
  ami_id           = "ami-0c55b159cbfafe1f0"
  instance_type    = "t3.medium"
  key_name         = "prod-key"
  
  # Networking
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_ids = [aws_security_group.api.id]

  # Storage configuration
  block_device_mappings = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  ]

  # IAM and user data
  iam_instance_profile_name = aws_iam_instance_profile.api.name
  user_data_base64         = base64encode(file("${path.module}/user-data.sh"))

  # Auto Scaling
  desired_capacity = 4
  min_size         = 2
  max_size         = 10

  # Enable auto scaling policies
  enable_scaling_policies = true
  cpu_high_threshold     = 75
  cpu_low_threshold      = 25

  # Instance refresh for zero-downtime updates
  enable_instance_refresh = true
  instance_refresh_min_healthy_percentage = 90

  tags = {
    Environment = "production"
    Application = "api-service"
    Team        = "backend"
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for instances | `list(string)` | n/a | yes |
| ami_id | AMI ID for EC2 instances | `string` | `"ami-0c55b159cbfafe1f0"` | no |
| instance_type | EC2 instance type | `string` | `"t2.micro"` | no |
| key_name | EC2 Key Pair name for SSH access | `string` | `"my-key-pair"` | no |
| security_group_ids | List of security group IDs | `list(string)` | `[]` | no |
| desired_capacity | Desired number of instances | `number` | `3` | no |
| min_size | Minimum number of instances | `number` | `1` | no |
| max_size | Maximum number of instances | `number` | `5` | no |
| health_check_type | Health check type (EC2/ELB) | `string` | `"EC2"` | no |
| target_group_arns | List of target group ARNs | `list(string)` | `[]` | no |
| enable_scaling_policies | Enable auto scaling policies | `bool` | `false` | no |
| block_device_mappings | List of block device mappings | `list(object)` | `[default]` | no |
| user_data_base64 | Base64 encoded user data | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| launch_template_id | ID of the launch template |
| launch_template_arn | ARN of the launch template |
| autoscaling_group_id | ID of the Auto Scaling Group |
| autoscaling_group_name | Name of the Auto Scaling Group |
| autoscaling_group_arn | ARN of the Auto Scaling Group |
| scale_up_policy_arn | ARN of the scale up policy |
| scale_down_policy_arn | ARN of the scale down policy |

## Security Groups

The module creates a security group with the following rules:

**Ingress:**
- Port 80 (HTTP) from anywhere (0.0.0.0/0)

**Egress:**
- All traffic to anywhere (0.0.0.0/0)

## Auto Scaling Features

- **Health Checks**: EC2 health checks with configurable grace period
- **Multi-AZ**: Instances distributed across all provided subnets
- **Load Balancer Integration**: Automatic target group registration
- **Launch Template**: Consistent instance configuration

## Best Practices

1. **AMI Selection**: Use the latest Amazon Linux 2 or Ubuntu LTS AMIs
2. **Instance Types**: Choose appropriate instance types for your workload
3. **Key Pairs**: Use separate key pairs for different environments
4. **Health Checks**: Configure meaningful health check endpoints
5. **Scaling**: Set appropriate min/max values based on expected load
6. **Monitoring**: Enable CloudWatch monitoring for all instances
7. **Security**: Regularly update AMIs and patch instances

## Cost Optimization

- **Instance Types**: Use burstable instances (t3/t4g) for variable workloads
- **Spot Instances**: Consider spot instances for non-critical workloads
- **Right Sizing**: Monitor CPU/memory usage and adjust instance types
- **Auto Scaling**: Use auto scaling to match capacity with demand

## Monitoring and Logging

The module integrates with:
- **CloudWatch**: Instance and application metrics
- **ALB Access Logs**: HTTP request logging (configure separately)
- **VPC Flow Logs**: Network traffic analysis (configure separately)

## Integration Examples

### With VPC Module
```hcl
module "vpc" {
  source = "./modules/vpc"
  # ... configuration
}

module "ec2" {
  source = "./modules/ec2"
  
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  # ... other configuration
}
```

### With Route53 Module
```hcl
module "dns" {
  source = "./modules/route53"
  # ... configuration
}

module "ec2" {
  source = "./modules/ec2"
  
  hosted_zone_id = module.dns.hosted_zone_id
  domain_name    = "app.${module.dns.domain_name}"
  # ... other configuration
}
```