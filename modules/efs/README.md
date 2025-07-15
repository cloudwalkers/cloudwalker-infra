# AWS EFS Module

This Terraform module creates and manages AWS Elastic File System (EFS) resources for scalable, shared file storage across multiple EC2 instances and containers.

## Features

- **Fully Managed NFS**: POSIX-compliant file system with automatic scaling
- **Multi-AZ Availability**: High availability across multiple availability zones
- **Performance Modes**: General Purpose and Max I/O for different workload requirements
- **Throughput Modes**: Bursting and Provisioned throughput options
- **Encryption**: At-rest and in-transit encryption with KMS integration
- **Access Points**: Fine-grained access control for multi-tenant applications
- **Automatic Backups**: Integration with AWS Backup service
- **Cross-Region Replication**: Disaster recovery and compliance support
- **Lifecycle Management**: Cost optimization with Infrequent Access storage class

## Performance Modes

### General Purpose
- **Use Case**: Most file systems and applications
- **Performance**: Up to 7,000 file operations per second
- **Latency**: Lowest latency per operation
- **Recommended**: Default choice for most workloads

### Max I/O
- **Use Case**: Applications requiring higher performance
- **Performance**: Higher levels of aggregate throughput and operations per second
- **Latency**: Slightly higher latencies for file operations
- **Recommended**: High-performance computing and media processing

## Throughput Modes

### Bursting Throughput
- **Baseline**: 50 MiB/s per TB of storage
- **Burst**: Up to 100 MiB/s for file systems under 1 TB
- **Credits**: Burst credits accumulate when not using full baseline
- **Cost**: No additional charges

### Provisioned Throughput
- **Performance**: Consistent throughput independent of storage size
- **Range**: 1 MiB/s to 1,024 MiB/s
- **Use Case**: Applications requiring consistent high throughput
- **Cost**: Additional charges for provisioned throughput

## Usage Examples

### Basic EFS File System

```hcl
module "basic_efs" {
  source = "./modules/efs"

  name                = "app-shared-storage"
  environment         = "prod"
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  tags = {
    Project = "MyApplication"
  }
}
```

### High-Performance EFS

```hcl
module "high_performance_efs" {
  source = "./modules/efs"

  name                   = "data-processing-storage"
  environment            = "prod"
  performance_mode       = "maxIO"
  throughput_mode        = "provisioned"
  provisioned_throughput = 500  # 500 MiB/s

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.compute.security_group_id]

  tags = {
    Workload    = "data-processing"
    Performance = "high"
  }
}
```

### Secure EFS with Encryption

```hcl
module "secure_efs" {
  source = "./modules/efs"

  name        = "secure-file-storage"
  environment = "prod"
  encrypted   = true
  kms_key_id  = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.app.security_group_id]

  backup_enabled = true

  # Cross-region replication for DR
  replication_configuration = {
    destination_region = "us-east-1"
    kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/87654321-4321-4321-4321-210987654321"
  }

  tags = {
    Compliance = "SOC2"
    Encrypted  = "true"
  }
}
```

### Multi-Tenant EFS with Access Points

```hcl
module "multi_tenant_efs" {
  source = "./modules/efs"

  name        = "multi-tenant-storage"
  environment = "prod"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.apps.security_group_id]

  access_points = {
    app1 = {
      posix_user = {
        gid = 1001
        uid = 1001
      }
      root_directory = {
        path = "/app1"
        creation_info = {
          owner_gid   = 1001
          owner_uid   = 1001
          permissions = "755"
        }
      }
      tags = {
        Application = "app1"
      }
    }
    app2 = {
      posix_user = {
        gid = 1002
        uid = 1002
      }
      root_directory = {
        path = "/app2"
        creation_info = {
          owner_gid   = 1002
          owner_uid   = 1002
          permissions = "750"
        }
      }
      tags = {
        Application = "app2"
      }
    }
  }

  tags = {
    Architecture = "multi-tenant"
  }
}
```

### EFS for Kubernetes/EKS

```hcl
module "eks_storage" {
  source = "./modules/efs"

  name        = "eks-persistent-storage"
  environment = "prod"

  vpc_id                     = module.eks.vpc_id
  subnet_ids                 = module.eks.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]

  access_points = {
    default = {
      root_directory = {
        path = "/default"
        creation_info = {
          owner_gid   = 0
          owner_uid   = 0
          permissions = "755"
        }
      }
    }
    production = {
      root_directory = {
        path = "/production"
        creation_info = {
          owner_gid   = 1000
          owner_uid   = 1000
          permissions = "750"
        }
      }
    }
  }

  tags = {
    Platform = "kubernetes"
  }
}
```

### Cost-Optimized EFS with Lifecycle Policy

```hcl
module "cost_optimized_efs" {
  source = "./modules/efs"

  name        = "archive-storage"
  environment = "prod"

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/16"]

  # Aggressive lifecycle policy for cost optimization
  lifecycle_policy = {
    transition_to_ia                    = "AFTER_7_DAYS"
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Purpose       = "archive"
    CostOptimized = "true"
  }
}
```

## Input Variables

### General Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | `string` | - | Name of the EFS file system |
| `environment` | `string` | `"dev"` | Environment name for tagging |
| `tags` | `map(string)` | `{}` | Additional tags for resources |
| `create_file_system` | `bool` | `true` | Whether to create the file system |
| `creation_token` | `string` | `null` | Unique creation token (auto-generated if not provided) |

### Performance Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `performance_mode` | `string` | `"generalPurpose"` | Performance mode (generalPurpose or maxIO) |
| `throughput_mode` | `string` | `"bursting"` | Throughput mode (bursting or provisioned) |
| `provisioned_throughput` | `number` | `null` | Provisioned throughput in MiB/s (1-1024) |

### Encryption Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `encrypted` | `bool` | `true` | Enable encryption at rest |
| `kms_key_id` | `string` | `null` | KMS key ID for encryption |

### Networking Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `vpc_id` | `string` | - | VPC ID where EFS will be created |
| `subnet_ids` | `list(string)` | - | List of subnet IDs for mount targets |
| `allowed_cidr_blocks` | `list(string)` | `[]` | CIDR blocks allowed to access EFS |
| `allowed_security_group_ids` | `list(string)` | `[]` | Security group IDs allowed to access EFS |

### Lifecycle and Backup

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `lifecycle_policy` | `object` | `null` | Lifecycle policy for IA transition |
| `backup_enabled` | `bool` | `true` | Enable automatic backups |

### Access Points

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `access_points` | `map(object)` | `{}` | Map of access points to create |

### File System Policy

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `file_system_policy` | `string` | `null` | JSON policy document for file system |
| `bypass_policy_lockout_safety_check` | `bool` | `false` | Bypass policy lockout safety check |

### Replication

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `replication_configuration` | `object` | `null` | Cross-region replication configuration |

## Outputs

### File System Information

| Output | Description |
|--------|-------------|
| `file_system_id` | ID of the EFS file system |
| `file_system_arn` | ARN of the EFS file system |
| `creation_token` | Creation token of the file system |
| `dns_name` | DNS name of the file system |
| `regional_dns_name` | Regional DNS name |

### Mount Target Information

| Output | Description |
|--------|-------------|
| `mount_target_ids` | List of mount target IDs |
| `mount_target_dns_names` | List of mount target DNS names |
| `mount_target_ip_addresses` | List of mount target IP addresses |
| `mount_target_availability_zones` | List of AZs with mount targets |

### Security Group Information

| Output | Description |
|--------|-------------|
| `security_group_id` | ID of the EFS security group |
| `security_group_arn` | ARN of the EFS security group |
| `security_group_name` | Name of the EFS security group |

### Access Points

| Output | Description |
|--------|-------------|
| `access_point_ids` | Map of access point names to IDs |
| `access_point_arns` | Map of access point names to ARNs |

### Mount Commands

| Output | Description |
|--------|-------------|
| `mount_command_nfs` | NFS mount command |
| `mount_command_efs_utils` | EFS utils mount command |
| `mount_command_efs_utils_encrypted` | EFS utils mount with encryption in transit |

## Best Practices

### Performance Optimization
- **Choose appropriate performance mode** based on your workload requirements
- **Use provisioned throughput** for consistent high-performance needs
- **Distribute I/O across multiple clients** for better performance
- **Use appropriate mount options** for your use case

### Security
- **Always enable encryption** for sensitive data
- **Use security groups** instead of CIDR blocks when possible
- **Implement access points** for multi-tenant applications
- **Use IAM policies** for fine-grained access control

### Cost Optimization
- **Use lifecycle policies** to transition to IA storage class
- **Monitor file access patterns** to optimize lifecycle settings
- **Use bursting throughput** unless consistent high throughput is required
- **Clean up unused access points** and mount targets

### High Availability
- **Deploy mount targets** across multiple availability zones
- **Use cross-region replication** for disaster recovery
- **Enable automatic backups** for data protection
- **Monitor file system health** with CloudWatch

## Integration Examples

### With EC2 Instances

```bash
# Install EFS utils
sudo yum install -y amazon-efs-utils

# Mount using EFS utils
sudo mount -t efs ${module.efs.file_system_id}:/ /mnt/efs

# Mount with encryption in transit
sudo mount -t efs -o tls ${module.efs.file_system_id}:/ /mnt/efs

# Add to /etc/fstab for persistent mounting
echo "${module.efs.file_system_id}:/ /mnt/efs efs defaults,_netdev" >> /etc/fstab
```

### With EKS/Kubernetes

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${module.efs.file_system_id}
  directoryPerms: "700"
```

### With ECS Tasks

```json
{
  "name": "efs-volume",
  "efsVolumeConfiguration": {
    "fileSystemId": "${module.efs.file_system_id}",
    "transitEncryption": "ENABLED",
    "authorizationConfig": {
      "accessPointId": "${module.efs.access_point_ids.app1}"
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | ~> 5.0 |
| random | ~> 3.1 |

## Resources Created

- `aws_efs_file_system` - The EFS file system
- `aws_efs_mount_target` - Mount targets in each subnet
- `aws_security_group` - Security group for EFS access
- `aws_efs_backup_policy` - Automatic backup configuration
- `aws_efs_access_point` - Application-specific access points
- `aws_efs_file_system_policy` - Resource-based access policy
- `aws_efs_replication_configuration` - Cross-region replication

## License

This module is released under the MIT License.