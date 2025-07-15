# EKS Module

This module creates a complete AWS EKS (Elastic Kubernetes Service) cluster with managed node groups, including all necessary IAM roles, security groups, and networking configuration.

## Features

- **EKS Cluster**: Fully managed Kubernetes control plane
- **Managed Node Groups**: Auto-scaling worker nodes with configurable instance types
- **IAM Integration**: Automatic creation of cluster and node group IAM roles
- **VPC Integration**: Support for both public and private subnets
- **Security**: Configurable API server endpoint access (public/private)
- **Capacity Types**: Support for On-Demand and Spot instances
- **Auto Scaling**: Configurable min/max/desired node counts
- **Multiple Instance Types**: Support for mixed instance types

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    EKS Cluster                             │
│                 (Control Plane)                            │
├─────────────────────────────────────────────────────────────┤
│  API Server Endpoint: Public/Private                       │
│  Kubernetes Version: 1.28                                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                 Node Groups                                │
├─────────────────────────────────────────────────────────────┤
│  Private Subnets                                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Node 1    │  │   Node 2    │  │   Node 3    │         │
│  │   AZ-1a     │  │   AZ-1b     │  │   AZ-1c     │         │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │         │
│  │ │  Pods   │ │  │ │  Pods   │ │  │ │  Pods   │ │         │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## Usage

### Basic EKS Cluster

```hcl
module "eks_cluster" {
  source = "./modules/eks"

  cluster_name       = "my-eks-cluster"
  kubernetes_version = "1.28"

  # Networking
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Node Group Configuration
  instance_types   = ["t3.medium"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 3
  min_size         = 1
  max_size         = 5

  tags = {
    Environment = "production"
    Application = "my-app"
  }
}
```

### Production EKS Cluster with Mixed Instance Types

```hcl
module "prod_eks" {
  source = "./modules/eks"

  cluster_name       = "prod-eks-cluster"
  kubernetes_version = "1.28"

  # Networking - Private cluster
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  endpoint_private_access = true
  endpoint_public_access  = false

  # Node Group - Production configuration
  instance_types   = ["t3.large", "t3.xlarge"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 6
  min_size         = 3
  max_size         = 12

  tags = {
    Environment = "production"
    Team        = "platform"
    Criticality = "high"
    Monitoring  = "enabled"
  }
}
```

### Cost-Optimized EKS with Spot Instances

```hcl
module "dev_eks" {
  source = "./modules/eks"

  cluster_name       = "dev-eks-cluster"
  kubernetes_version = "1.28"

  # Networking
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Cost optimization with Spot instances
  instance_types   = ["t3.medium", "t3.large"]
  capacity_type    = "SPOT"
  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  tags = {
    Environment   = "development"
    CostOptimized = "true"
    Team          = "development"
  }
}
```

### Multi-Environment EKS Setup

```hcl
# Production Cluster
module "prod_eks" {
  source = "./modules/eks"

  cluster_name       = "prod-k8s"
  kubernetes_version = "1.28"

  private_subnet_ids = module.prod_vpc.private_subnet_ids
  public_subnet_ids  = module.prod_vpc.public_subnet_ids

  # Production-grade configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["203.0.113.0/24"]  # Office IP

  instance_types   = ["t3.large"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 6
  min_size         = 3
  max_size         = 15

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}

# Development Cluster
module "dev_eks" {
  source = "./modules/eks"

  cluster_name       = "dev-k8s"
  kubernetes_version = "1.28"

  private_subnet_ids = module.dev_vpc.private_subnet_ids
  public_subnet_ids  = module.dev_vpc.public_subnet_ids

  # Development configuration
  instance_types   = ["t3.medium"]
  capacity_type    = "SPOT"
  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  tags = {
    Environment  = "development"
    AutoShutdown = "enabled"
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| kubernetes_version | Kubernetes version for the EKS cluster | `string` | `"1.28"` | no |
| private_subnet_ids | List of private subnet IDs | `list(string)` | n/a | yes |
| public_subnet_ids | List of public subnet IDs | `list(string)` | `[]` | no |
| endpoint_private_access | Enable private API server endpoint | `bool` | `true` | no |
| endpoint_public_access | Enable public API server endpoint | `bool` | `true` | no |
| public_access_cidrs | CIDR blocks for public API access | `list(string)` | `["0.0.0.0/0"]` | no |
| capacity_type | Capacity type (ON_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | no |
| instance_types | List of instance types for node group | `list(string)` | `["t3.medium"]` | no |
| desired_capacity | Desired number of nodes | `number` | `2` | no |
| max_size | Maximum number of nodes | `number` | `4` | no |
| min_size | Minimum number of nodes | `number` | `1` | no |
| tags | A map of tags to assign to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ID of the EKS cluster |
| cluster_arn | ARN of the EKS cluster |
| cluster_endpoint | Endpoint for Kubernetes API server |
| cluster_version | Kubernetes server version |
| cluster_certificate_authority_data | Base64 encoded certificate data |
| cluster_security_group_id | Security group ID attached to the cluster |
| node_group_arn | ARN of the EKS Node Group |
| node_group_status | Status of the EKS Node Group |

## IAM Roles

The module automatically creates the following IAM roles:

### Cluster Service Role
- **AmazonEKSClusterPolicy**: Allows EKS to manage cluster resources
- **AmazonEKSVPCResourceController**: Manages VPC resources for the cluster

### Node Group Role
- **AmazonEKSWorkerNodePolicy**: Allows worker nodes to connect to cluster
- **AmazonEKS_CNI_Policy**: Provides IP addresses for pods
- **AmazonEC2ContainerRegistryReadOnly**: Pulls container images from ECR

## Security Considerations

1. **API Server Access**: Configure endpoint access based on security requirements
2. **CIDR Restrictions**: Limit public access to known IP ranges
3. **Private Subnets**: Deploy worker nodes in private subnets
4. **Security Groups**: Automatic security group creation with minimal required access
5. **IAM Roles**: Least privilege access for cluster and node operations

## Best Practices

1. **Kubernetes Version**: Keep Kubernetes version up to date
2. **Node Groups**: Use multiple node groups for different workload types
3. **Instance Types**: Choose appropriate instance types for your workloads
4. **Capacity Planning**: Set appropriate min/max values for auto scaling
5. **Monitoring**: Enable CloudWatch Container Insights
6. **Networking**: Use private subnets for worker nodes
7. **Cost Optimization**: Consider Spot instances for non-critical workloads

## Cost Optimization

- **Spot Instances**: Up to 90% cost savings for fault-tolerant workloads
- **Right Sizing**: Monitor resource usage and adjust instance types
- **Cluster Autoscaler**: Automatically scale nodes based on pod requirements
- **Horizontal Pod Autoscaler**: Scale pods based on CPU/memory usage

## Kubectl Configuration

After cluster creation, configure kubectl:

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

## Add-ons and Extensions

Consider installing these common EKS add-ons:

- **AWS Load Balancer Controller**: For ALB/NLB integration
- **EBS CSI Driver**: For persistent volume support
- **Cluster Autoscaler**: For automatic node scaling
- **Metrics Server**: For resource metrics
- **AWS Node Termination Handler**: For Spot instance handling

## Integration Examples

### With VPC Module
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

### With Load Balancer Module
```hcl
module "eks" {
  source = "./modules/eks"
  # ... configuration
}

# Deploy ALB Controller via Helm or kubectl after cluster creation
```