# VPC Module

This module creates a complete AWS VPC infrastructure with public and private subnets, internet gateway, NAT gateways, route tables, and security groups.

## Features

- **Multi-AZ VPC**: Automatically distributes subnets across available AZs
- **Public & Private Subnets**: Configurable CIDR blocks for each subnet type
- **Internet Gateway**: For public subnet internet access
- **NAT Gateways**: One per AZ for private subnet outbound internet access
- **Route Tables**: Automatic routing configuration for public and private subnets
- **Security Groups**: Default security group with common ports (80, 443, 22)
- **DNS Support**: Enabled DNS hostnames and resolution
- **Elastic IPs**: Automatic EIP allocation for NAT gateways

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC (10.0.0.0/16)                   │
├─────────────────────────────────────────────────────────────┤
│  AZ-1a                           │  AZ-1b                   │
│  ┌─────────────────────────────┐  │  ┌─────────────────────┐ │
│  │ Public Subnet (10.0.1.0/24)│  │  │Public Subnet        │ │
│  │ ┌─────────┐ ┌─────────────┐ │  │  │(10.0.2.0/24)       │ │
│  │ │   IGW   │ │  NAT-GW-1   │ │  │  │ ┌─────────────────┐ │ │
│  │ └─────────┘ └─────────────┘ │  │  │ │   NAT-GW-2      │ │ │
│  └─────────────────────────────┘  │  │ └─────────────────┘ │ │
│  ┌─────────────────────────────┐  │  └─────────────────────┘ │
│  │Private Subnet (10.0.10.0/24)│ │  ┌─────────────────────┐ │
│  │                             │  │  │Private Subnet       │ │
│  │                             │  │  │(10.0.20.0/24)      │ │
│  └─────────────────────────────┘  │  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic VPC

```hcl
module "vpc" {
  source = "./modules/vpc"

  name_prefix             = "my-app"
  vpc_cidr_block          = "10.0.0.0/16"
  public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
  allowed_ips             = ["0.0.0.0/0"]

  tags = {
    Environment = "production"
    Project     = "my-app"
  }
}
```

### Custom Configuration

```hcl
module "custom_vpc" {
  source = "./modules/vpc"

  name_prefix             = "custom"
  vpc_cidr_block          = "172.16.0.0/16"
  public_subnet_cidrs     = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  private_subnet_cidrs    = ["172.16.10.0/24", "172.16.20.0/24", "172.16.30.0/24"]
  
  # Restrict access to specific IPs
  allowed_ips = [
    "203.0.113.0/24",  # Office network
    "198.51.100.0/24"  # Partner network
  ]

  tags = {
    Environment = "production"
    Team        = "platform"
    CostCenter  = "engineering"
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_cidr_block | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnet_cidrs | List of CIDR blocks for public subnets | `list(string)` | `["10.0.1.0/24", "10.0.2.0/24"]` | no |
| private_subnet_cidrs | List of CIDR blocks for private subnets | `list(string)` | `["10.0.10.0/24", "10.0.20.0/24"]` | no |
| allowed_ips | List of IP addresses allowed to access resources | `list(string)` | `["0.0.0.0/0"]` | no |
| name_prefix | Prefix for resource names | `string` | `"main"` | no |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| internet_gateway_id | ID of the Internet Gateway |
| public_subnet_ids | IDs of the public subnets |
| private_subnet_ids | IDs of the private subnets |
| nat_gateway_ids | IDs of the NAT Gateways |
| nat_gateway_ips | Public IPs of the NAT Gateways |
| default_security_group_id | ID of the default security group |
| public_route_table_id | ID of the public route table |
| private_route_table_ids | IDs of the private route tables |

## Security Group Rules

The default security group includes:

**Ingress Rules:**
- Port 80 (HTTP) from allowed IPs
- Port 443 (HTTPS) from allowed IPs  
- Port 22 (SSH) from allowed IPs

**Egress Rules:**
- All traffic to anywhere (0.0.0.0/0)

## Best Practices

1. **CIDR Planning**: Plan your CIDR blocks carefully to avoid conflicts
2. **Multi-AZ**: Always use at least 2 AZs for high availability
3. **Subnet Sizing**: Size subnets appropriately for your expected resources
4. **Security**: Restrict `allowed_ips` to known networks in production
5. **Tagging**: Use consistent tagging for cost allocation and management
6. **NAT Gateways**: Consider costs - NAT gateways are charged per hour and per GB

## Cost Considerations

- **NAT Gateways**: ~$45/month per NAT Gateway + data processing charges
- **Elastic IPs**: Free when attached to running instances
- **VPC**: No charge for the VPC itself
- **Data Transfer**: Charges apply for data transfer between AZs

## Integration Examples

### With EC2 Module
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

### With EKS Module
```hcl
module "vpc" {
  source = "./modules/vpc"
  # ... configuration
}

module "eks" {
  source = "./modules/eks"
  
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  # ... other configuration
}
```