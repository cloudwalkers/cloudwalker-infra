# AWS VPC Endpoints Module

This Terraform module creates and manages AWS VPC endpoints for secure, private connectivity to AWS services without traversing the public internet.

## Features

- **Gateway Endpoints**: Cost-effective access to S3 and DynamoDB with no additional charges
- **Interface Endpoints**: Private IP-based access to AWS services using Elastic Network Interfaces
- **Security Groups**: Configurable network access control for interface endpoints
- **DNS Resolution**: Private DNS names for seamless service integration
- **Access Policies**: Fine-grained IAM policies for endpoint access control
- **Monitoring**: CloudWatch Events integration for endpoint state monitoring
- **Custom DNS**: Route 53 resolver rules for advanced DNS management
- **Multi-Service Support**: Pre-configured endpoints for common AWS services

## Endpoint Types

### Gateway Endpoints
- **Services**: S3 and DynamoDB only
- **Cost**: No additional charges for data processing or hourly usage
- **Implementation**: Route table entries direct traffic to AWS services
- **Use Case**: Cost-effective access to S3 and DynamoDB

### Interface Endpoints
- **Services**: Most AWS services (EC2, Lambda, SNS, SQS, etc.)
- **Cost**: Hourly charges and data processing fees apply
- **Implementation**: Elastic Network Interfaces with private IP addresses
- **Use Case**: Private access to AWS APIs and services

## Usage Examples

### Basic Gateway Endpoints

```hcl
module "basic_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "basic"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
    dynamodb = {
      service_name      = "com.amazonaws.us-west-2.dynamodb"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
  }

  tags = {
    Purpose = "cost-optimization"
  }
}
```

### EC2 Management Endpoints

```hcl
module "ec2_management" {
  source = "./modules/vpc-endpoints"

  name_prefix = "ec2-mgmt"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  endpoints = {
    ec2 = {
      service_name        = "com.amazonaws.us-west-2.ec2"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ssm = {
      service_name        = "com.amazonaws.us-west-2.ssm"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ssmmessages = {
      service_name        = "com.amazonaws.us-west-2.ssmmessages"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ec2messages = {
      service_name        = "com.amazonaws.us-west-2.ec2messages"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Purpose = "ec2-management"
  }
}
```

### Container Workload Endpoints

```hcl
module "container_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "container"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  create_security_group = true
  allowed_cidr_blocks   = [module.vpc.vpc_cidr_block]

  endpoints = {
    ecr_api = {
      service_name        = "com.amazonaws.us-west-2.ecr.api"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ecr_dkr = {
      service_name        = "com.amazonaws.us-west-2.ecr.dkr"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    ecs = {
      service_name        = "com.amazonaws.us-west-2.ecs"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    s3 = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
    }
  }

  tags = {
    Workload = "containers"
  }
}
```

### Secure Endpoints with Policies

```hcl
module "secure_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "secure"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  endpoints = {
    s3_restricted = {
      service_name      = "com.amazonaws.us-west-2.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = module.vpc.private_route_table_ids
      
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = "*"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:ListBucket"
            ]
            Resource = [
              "arn:aws:s3:::company-prod-data/*",
              "arn:aws:s3:::company-prod-data"
            ]
          }
        ]
      })
    }
  }

  tags = {
    Security = "restricted-access"
  }
}
```

### Monitored Endpoints

```hcl
module "monitored_endpoints" {
  source = "./modules/vpc-endpoints"

  name_prefix = "monitored"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id

  enable_endpoint_monitoring = true
  monitoring_sns_topic_arn   = module.alerts.topic_arn

  endpoints = {
    logs = {
      service_name        = "com.amazonaws.us-west-2.logs"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
    monitoring = {
      service_name        = "com.amazonaws.us-west-2.monitoring"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = module.vpc.private_subnet_ids
      private_dns_enabled = true
    }
  }

  tags = {
    Monitoring = "enabled"
  }
}
```

## Input Variables

### General Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name_prefix` | `string` | `"vpc-endpoints"` | Prefix for naming resources |
| `environment` | `string` | `"dev"` | Environment name for tagging |
| `tags` | `map(string)` | `{}` | Additional tags for resources |
| `vpc_id` | `string` | - | VPC ID where endpoints will be created |

### Endpoint Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `endpoints` | `map(object)` | `{}` | Map of VPC endpoints to create |
| `route_table_ids` | `list(string)` | `[]` | Route table IDs for gateway endpoints |
| `auto_accept` | `bool` | `true` | Auto-associate with private route tables |

### Security Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_security_group` | `bool` | `true` | Create default security group for interface endpoints |
| `allowed_cidr_blocks` | `list(string)` | `["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]` | CIDR blocks allowed to access endpoints |
| `allow_http` | `bool` | `false` | Allow HTTP traffic in addition to HTTPS |

### DNS Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_resolver_rules` | `bool` | `false` | Create Route 53 resolver rules |
| `resolver_rules` | `map(object)` | `{}` | Custom DNS resolver rules |

### Monitoring Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_endpoint_monitoring` | `bool` | `false` | Enable CloudWatch Events monitoring |
| `monitoring_sns_topic_arn` | `string` | `null` | SNS topic for monitoring notifications |

## Outputs

### Endpoint Information

| Output | Description |
|--------|-------------|
| `interface_endpoint_ids` | Map of interface endpoint names to IDs |
| `interface_endpoint_arns` | Map of interface endpoint names to ARNs |
| `gateway_endpoint_ids` | Map of gateway endpoint names to IDs |
| `gateway_endpoint_arns` | Map of gateway endpoint names to ARNs |
| `all_endpoint_ids` | Map of all endpoint names to IDs |

### Security Group Information

| Output | Description |
|--------|-------------|
| `security_group_id` | ID of the VPC endpoints security group |
| `security_group_arn` | ARN of the VPC endpoints security group |

### Summary Information

| Output | Description |
|--------|-------------|
| `endpoint_summary` | Summary of created endpoints by type |

## Common AWS Services

### Gateway Endpoints (No Additional Cost)
- **S3**: `com.amazonaws.region.s3`
- **DynamoDB**: `com.amazonaws.region.dynamodb`

### Interface Endpoints (Hourly + Data Processing Charges)
- **EC2**: `com.amazonaws.region.ec2`
- **SSM**: `com.amazonaws.region.ssm`
- **SSM Messages**: `com.amazonaws.region.ssmmessages`
- **EC2 Messages**: `com.amazonaws.region.ec2messages`
- **CloudWatch Logs**: `com.amazonaws.region.logs`
- **CloudWatch Monitoring**: `com.amazonaws.region.monitoring`
- **ECR API**: `com.amazonaws.region.ecr.api`
- **ECR Docker**: `com.amazonaws.region.ecr.dkr`
- **ECS**: `com.amazonaws.region.ecs`
- **Lambda**: `com.amazonaws.region.lambda`
- **Secrets Manager**: `com.amazonaws.region.secretsmanager`
- **KMS**: `com.amazonaws.region.kms`
- **SNS**: `com.amazonaws.region.sns`
- **SQS**: `com.amazonaws.region.sqs`

## Best Practices

### Cost Optimization
- **Use gateway endpoints** for S3 and DynamoDB when possible (no additional charges)
- **Consolidate interface endpoints** across multiple subnets in the same AZ
- **Monitor endpoint usage** with CloudWatch metrics
- **Remove unused endpoints** to avoid unnecessary charges

### Security
- **Use restrictive security groups** for interface endpoints
- **Implement endpoint policies** to limit access to specific resources
- **Enable private DNS** for seamless service integration
- **Monitor endpoint access** with VPC Flow Logs

### High Availability
- **Deploy interface endpoints** across multiple Availability Zones
- **Use multiple subnets** for interface endpoints in different AZs
- **Monitor endpoint health** with CloudWatch Events
- **Implement failover strategies** for critical services

### Performance
- **Place endpoints close to workloads** to minimize latency
- **Use appropriate endpoint types** based on traffic patterns
- **Monitor endpoint performance** with CloudWatch metrics
- **Consider bandwidth requirements** for high-throughput applications

## Integration Examples

### With EC2 Instances

```bash
# Test connectivity to S3 via VPC endpoint
aws s3 ls --region us-west-2

# Test SSM connectivity
aws ssm describe-instance-information --region us-west-2
```

### With ECS Tasks

```json
{
  "family": "my-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "my-container",
      "image": "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-app:latest",
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/my-task",
          "awslogs-region": "us-west-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

### With Lambda Functions

```python
import boto3

# Lambda function using VPC endpoints
def lambda_handler(event, context):
    # S3 client will use VPC endpoint automatically
    s3 = boto3.client('s3')
    
    # DynamoDB client will use VPC endpoint automatically
    dynamodb = boto3.client('dynamodb')
    
    # Process data using private connectivity
    return {'statusCode': 200}
```

## Troubleshooting

### Common Issues

1. **DNS Resolution Problems**
   - Ensure `private_dns_enabled = true` for interface endpoints
   - Check VPC DNS settings (`enableDnsHostnames` and `enableDnsSupport`)

2. **Security Group Issues**
   - Verify security groups allow HTTPS (443) traffic
   - Check source CIDR blocks or security groups

3. **Route Table Configuration**
   - Ensure gateway endpoints are associated with correct route tables
   - Verify route table associations for private subnets

4. **Service Availability**
   - Check if the service supports VPC endpoints in your region
   - Verify correct service name format

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |

## Resources Created

- `aws_vpc_endpoint` - VPC endpoints (Gateway and Interface types)
- `aws_security_group` - Security group for interface endpoints
- `aws_route53_resolver_rule` - Custom DNS resolver rules
- `aws_route53_resolver_rule_association` - DNS rule associations
- `aws_cloudwatch_event_rule` - Endpoint monitoring rules
- `aws_cloudwatch_event_target` - Monitoring notification targets

## License

This module is released under the MIT License.