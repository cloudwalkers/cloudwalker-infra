# AWS VPC Transit Gateway Module

This Terraform module creates and manages AWS Transit Gateway for scalable network connectivity between VPCs, on-premises networks, and AWS services.

## Features

- **Centralized Connectivity**: Hub-and-spoke network architecture for multiple VPCs
- **Hybrid Connectivity**: Site-to-Site VPN and Direct Connect Gateway integration
- **Cross-Region Peering**: Global network connectivity across AWS regions
- **Advanced Routing**: Custom route tables with propagation and association controls
- **Network Segmentation**: Isolated routing domains for security and compliance
- **Multicast Support**: Efficient one-to-many communication patterns
- **Resource Sharing**: Cross-account sharing via AWS Resource Access Manager
- **Flow Logs**: Network traffic monitoring and analysis
- **High Availability**: Multi-AZ deployment with redundant connections

## Architecture Benefits

### Traditional VPC Peering vs Transit Gateway

**VPC Peering Limitations:**
- N×(N-1)/2 connections for full mesh (exponential growth)
- Complex routing table management
- No transitive routing
- Limited to 125 peering connections per VPC

**Transit Gateway Advantages:**
- Single hub for all connections (linear growth)
- Centralized routing management
- Transitive routing support
- Up to 5,000 VPC attachments per Transit Gateway

## Usage Examples

### Basic Multi-VPC Connectivity

```hcl
module "basic_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "basic-tgw"
  environment = "prod"
  description = "Basic Transit Gateway for VPC connectivity"

  vpc_attachments = {
    vpc_a = {
      vpc_id     = module.vpc_a.vpc_id
      subnet_ids = module.vpc_a.private_subnet_ids
    }
    vpc_b = {
      vpc_id     = module.vpc_b.vpc_id
      subnet_ids = module.vpc_b.private_subnet_ids
    }
    vpc_c = {
      vpc_id     = module.vpc_c.vpc_id
      subnet_ids = module.vpc_c.private_subnet_ids
    }
  }

  tags = {
    Purpose = "vpc-connectivity"
  }
}
```

### Enterprise Network with Segmentation

```hcl
module "enterprise_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "enterprise-tgw"
  environment = "prod"
  description = "Enterprise Transit Gateway with network segmentation"

  # Disable default routing for custom control
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  vpc_attachments = {
    production = {
      vpc_id     = module.prod_vpc.vpc_id
      subnet_ids = module.prod_vpc.private_subnet_ids
    }
    staging = {
      vpc_id     = module.staging_vpc.vpc_id
      subnet_ids = module.staging_vpc.private_subnet_ids
    }
    shared_services = {
      vpc_id     = module.shared_vpc.vpc_id
      subnet_ids = module.shared_vpc.private_subnet_ids
    }
  }

  # Custom route tables for segmentation
  route_tables = {
    production = {}
    non_production = {}
    shared_services = {}
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
  }

  # Route propagations
  route_table_propagations = {
    shared_to_prod = {
      attachment_name  = "shared_services"
      attachment_type  = "vpc"
      route_table_name = "production"
    }
  }

  tags = {
    Architecture = "enterprise"
    Segmentation = "enabled"
  }
}
```

### Hybrid Connectivity with VPN

```hcl
module "hybrid_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "hybrid-tgw"
  environment = "prod"
  description = "Hybrid connectivity with on-premises networks"

  amazon_side_asn   = 64512
  vpn_ecmp_support = "enable"

  vpc_attachments = {
    main_vpc = {
      vpc_id     = module.main_vpc.vpc_id
      subnet_ids = module.main_vpc.private_subnet_ids
    }
  }

  # Customer Gateways
  customer_gateways = {
    headquarters = {
      bgp_asn     = 65000
      ip_address  = "203.0.113.12"
      type        = "ipsec.1"
      device_name = "HQ-Firewall-01"
    }
  }

  # VPN connections
  vpn_connections = {
    hq_vpn = {
      customer_gateway_id = "headquarters"
      type               = "ipsec.1"
      static_routes_only = false
    }
  }

  tags = {
    Connectivity = "hybrid"
  }
}
```

### Cross-Region Connectivity

```hcl
module "multi_region_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "global-tgw-us-west"
  environment = "prod"
  description = "Multi-region Transit Gateway"

  vpc_attachments = {
    us_west_prod = {
      vpc_id     = module.us_west_vpc.vpc_id
      subnet_ids = module.us_west_vpc.private_subnet_ids
    }
  }

  # Cross-region peering
  peering_attachments = {
    us_east_peering = {
      peer_account_id         = data.aws_caller_identity.current.account_id
      peer_region            = "us-east-1"
      peer_transit_gateway_id = "tgw-0123456789abcdef0"
    }
  }

  tags = {
    Scope = "global"
  }
}
```

### Secure Transit Gateway with Inspection

```hcl
module "secure_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "secure-tgw"
  environment = "prod"
  description = "Security-focused Transit Gateway"

  # Security configuration
  auto_accept_shared_attachments  = "disable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  vpc_attachments = {
    application = {
      vpc_id                 = module.app_vpc.vpc_id
      subnet_ids             = module.app_vpc.private_subnet_ids
      appliance_mode_support = "enable"
    }
    security_inspection = {
      vpc_id                 = module.security_vpc.vpc_id
      subnet_ids             = module.security_vpc.private_subnet_ids
      appliance_mode_support = "enable"
    }
  }

  # Enable flow logs
  enable_flow_logs              = true
  flow_logs_destination_type    = "cloud-watch-logs"
  flow_logs_destination_arn     = module.cloudwatch_logs.log_group_arn
  flow_logs_iam_role_arn        = module.flow_logs_role.arn

  tags = {
    Security   = "inspection-enabled"
    Monitoring = "flow-logs-enabled"
  }
}
```

### Shared Services Architecture

```hcl
module "shared_services_transit_gateway" {
  source = "./modules/vpc-transit-gw"

  name        = "shared-services-tgw"
  environment = "prod"
  description = "Shared services for multi-account architecture"

  auto_accept_shared_attachments = "enable"

  vpc_attachments = {
    shared_services = {
      vpc_id     = module.shared_services_vpc.vpc_id
      subnet_ids = module.shared_services_vpc.private_subnet_ids
    }
  }

  # Enable cross-account sharing
  enable_resource_sharing   = true
  allow_external_principals = false
  shared_principals = [
    "123456789012",  # Production account
    "123456789013",  # Development account
  ]

  tags = {
    Purpose = "shared-services"
    Sharing = "cross-account"
  }
}
```

## Input Variables

### General Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | `string` | - | Name of the Transit Gateway |
| `environment` | `string` | `"dev"` | Environment name for tagging |
| `tags` | `map(string)` | `{}` | Additional tags for resources |
| `create_transit_gateway` | `bool` | `true` | Whether to create the Transit Gateway |
| `description` | `string` | `"Transit Gateway for centralized network connectivity"` | Description |

### Transit Gateway Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `amazon_side_asn` | `number` | `64512` | BGP ASN for Amazon side (64512-65534) |
| `auto_accept_shared_attachments` | `string` | `"disable"` | Auto-accept attachment requests |
| `auto_accept_shared_associations` | `string` | `"disable"` | Auto-accept association requests |
| `default_route_table_association` | `string` | `"enable"` | Default route table association |
| `default_route_table_propagation` | `string` | `"enable"` | Default route table propagation |
| `dns_support` | `string` | `"enable"` | DNS support |
| `vpn_ecmp_support` | `string` | `"enable"` | VPN ECMP support |
| `multicast_support` | `string` | `"disable"` | Multicast support |

### VPC Attachments

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_attachments` | `map(object)` | `{}` | Map of VPC attachments to create |

### Routing Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `route_tables` | `map(object)` | `{}` | Custom route tables |
| `route_table_associations` | `map(object)` | `{}` | Route table associations |
| `route_table_propagations` | `map(object)` | `{}` | Route table propagations |
| `static_routes` | `map(object)` | `{}` | Static routes |

### Hybrid Connectivity

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `customer_gateways` | `map(object)` | `{}` | Customer Gateways for VPN |
| `vpn_connections` | `map(object)` | `{}` | Site-to-Site VPN connections |
| `enable_dx_gateway_association` | `bool` | `false` | Enable Direct Connect Gateway |
| `dx_gateway_associations` | `map(object)` | `{}` | Direct Connect Gateway associations |

### Cross-Region Peering

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `peering_attachments` | `map(object)` | `{}` | Cross-region peering attachments |

### Resource Sharing

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_resource_sharing` | `bool` | `false` | Enable RAM resource sharing |
| `allow_external_principals` | `bool` | `false` | Allow external principals |
| `shared_principals` | `list(string)` | `[]` | Principals to share with |

### Monitoring

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_flow_logs` | `bool` | `false` | Enable VPC Flow Logs |
| `flow_logs_destination_type` | `string` | `"cloud-watch-logs"` | Flow logs destination type |
| `flow_logs_traffic_type` | `string` | `"ALL"` | Traffic type to capture |

## Outputs

### Transit Gateway Information

| Output | Description |
|--------|-------------|
| `transit_gateway_id` | ID of the Transit Gateway |
| `transit_gateway_arn` | ARN of the Transit Gateway |
| `transit_gateway_owner_id` | Owner ID of the Transit Gateway |
| `transit_gateway_association_default_route_table_id` | Default association route table ID |
| `transit_gateway_propagation_default_route_table_id` | Default propagation route table ID |

### Attachment Information

| Output | Description |
|--------|-------------|
| `vpc_attachment_ids` | Map of VPC attachment names to IDs |
| `vpc_attachment_arns` | Map of VPC attachment names to ARNs |
| `peering_attachment_ids` | Map of peering attachment names to IDs |

### Routing Information

| Output | Description |
|--------|-------------|
| `route_table_ids` | Map of route table names to IDs |
| `route_table_associations` | Route table association details |
| `route_table_propagations` | Route table propagation details |

### VPN Information

| Output | Description |
|--------|-------------|
| `customer_gateway_ids` | Map of Customer Gateway names to IDs |
| `vpn_connection_ids` | Map of VPN connection names to IDs |
| `vpn_connection_tunnel1_addresses` | VPN tunnel 1 addresses |
| `vpn_connection_tunnel2_addresses` | VPN tunnel 2 addresses |

## Best Practices

### Network Design
- **Use hub-and-spoke architecture** instead of full mesh VPC peering
- **Implement network segmentation** with custom route tables
- **Plan IP address space** carefully to avoid conflicts
- **Use consistent naming conventions** for resources

### Security
- **Disable default route tables** for production environments
- **Implement least privilege routing** with custom route tables
- **Use appliance mode** for security inspection VPCs
- **Enable flow logs** for monitoring and compliance

### High Availability
- **Deploy across multiple AZs** for VPC attachments
- **Use ECMP for VPN connections** to increase bandwidth and redundancy
- **Implement cross-region peering** for disaster recovery
- **Monitor connection health** with CloudWatch

### Cost Optimization
- **Consolidate traffic** through Transit Gateway instead of multiple NAT Gateways
- **Use Direct Connect** for high-volume on-premises traffic
- **Monitor data transfer costs** between regions and AZs
- **Right-size VPN connections** based on bandwidth requirements

## Integration Examples

### With VPC Module

```hcl
module "vpc" {
  source = "./modules/vpc"
  # VPC configuration
}

module "transit_gateway" {
  source = "./modules/vpc-transit-gw"

  vpc_attachments = {
    main = {
      vpc_id     = module.vpc.vpc_id
      subnet_ids = module.vpc.private_subnet_ids
    }
  }
}

# Update VPC route tables to use Transit Gateway
resource "aws_route" "tgw_route" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = module.transit_gateway.transit_gateway_id
}
```

### With Security Groups

```hcl
resource "aws_security_group_rule" "allow_tgw_traffic" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.app.id
}
```

### With CloudWatch Monitoring

```hcl
resource "aws_cloudwatch_metric_alarm" "tgw_packet_drop" {
  alarm_name          = "tgw-packet-drop-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "PacketDropCount"
  namespace           = "AWS/TransitGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors TGW packet drops"

  dimensions = {
    TransitGateway = module.transit_gateway.transit_gateway_id
  }
}
```

## Troubleshooting

### Common Issues

1. **Route Table Conflicts**
   - Check for overlapping CIDR blocks
   - Verify route table associations and propagations
   - Ensure proper route priorities

2. **VPN Connection Issues**
   - Verify Customer Gateway configuration
   - Check BGP ASN compatibility
   - Confirm tunnel status and routing

3. **Cross-Region Peering**
   - Ensure peering attachment is accepted in peer region
   - Verify route table configurations in both regions
   - Check security group rules

4. **DNS Resolution Problems**
   - Ensure DNS support is enabled
   - Check VPC DNS settings
   - Verify Route 53 resolver rules

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |

## Resources Created

- `aws_ec2_transit_gateway` - The Transit Gateway
- `aws_ec2_transit_gateway_vpc_attachment` - VPC attachments
- `aws_ec2_transit_gateway_route_table` - Custom route tables
- `aws_ec2_transit_gateway_route_table_association` - Route table associations
- `aws_ec2_transit_gateway_route_table_propagation` - Route propagations
- `aws_ec2_transit_gateway_route` - Static routes
- `aws_customer_gateway` - Customer Gateways for VPN
- `aws_vpn_connection` - Site-to-Site VPN connections
- `aws_ec2_transit_gateway_peering_attachment` - Cross-region peering
- `aws_dx_gateway_association` - Direct Connect Gateway associations
- `aws_ec2_transit_gateway_multicast_domain` - Multicast domains
- `aws_ram_resource_share` - Resource sharing configuration
- `aws_flow_log` - VPC Flow Logs

## License

This module is released under the MIT License.