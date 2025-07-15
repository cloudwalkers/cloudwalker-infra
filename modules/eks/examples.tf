# Example 1: Basic EKS Cluster for Development
/*
module "dev_eks" {
  source = "./modules/eks"

  cluster_name       = "dev-cluster"
  kubernetes_version = "1.28"

  # Networking
  private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  public_subnet_ids  = ["subnet-11111111", "subnet-22222222"]

  # Basic node group configuration
  instance_types   = ["t3.medium"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  tags = {
    Environment = "development"
    Team        = "platform"
    Purpose     = "testing"
  }
}
*/

# Example 2: Production EKS Cluster with High Availability
/*
module "prod_eks" {
  source = "./modules/eks"

  cluster_name       = "prod-cluster"
  kubernetes_version = "1.28"

  # Multi-AZ private subnets for high availability
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Secure API access
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = [
    "203.0.113.0/24",  # Office network
    "198.51.100.0/24"  # VPN network
  ]

  # Production-grade node configuration
  instance_types   = ["t3.large", "t3.xlarge"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 6
  min_size         = 3
  max_size         = 15

  tags = {
    Environment = "production"
    Application = "web-platform"
    Team        = "platform"
    Criticality = "high"
    Monitoring  = "enabled"
    Backup      = "required"
  }
}
*/

# Example 3: Cost-Optimized EKS with Spot Instances
/*
module "spot_eks" {
  source = "./modules/eks"

  cluster_name       = "spot-cluster"
  kubernetes_version = "1.28"

  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Cost optimization with Spot instances
  instance_types   = ["t3.medium", "t3.large", "t3.xlarge"]
  capacity_type    = "SPOT"
  desired_capacity = 3
  min_size         = 1
  max_size         = 8

  tags = {
    Environment   = "development"
    CostOptimized = "true"
    Workload      = "batch-processing"
    Team          = "data"
  }
}
*/

# Example 4: Private EKS Cluster for Security-Sensitive Workloads
/*
module "private_eks" {
  source = "./modules/eks"

  cluster_name       = "private-cluster"
  kubernetes_version = "1.28"

  private_subnet_ids = module.vpc.private_subnet_ids

  # Fully private cluster
  endpoint_private_access = true
  endpoint_public_access  = false

  # Secure node configuration
  instance_types   = ["t3.large"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 4
  min_size         = 2
  max_size         = 8

  tags = {
    Environment = "production"
    Security    = "high"
    Compliance  = "required"
    Team        = "security"
  }
}
*/

# Example 5: Multi-Environment EKS Setup
/*
# Production Environment
module "prod_k8s" {
  source = "./modules/eks"

  cluster_name       = "prod-k8s"
  kubernetes_version = "1.28"

  private_subnet_ids = module.prod_vpc.private_subnet_ids
  public_subnet_ids  = module.prod_vpc.public_subnet_ids

  # Production configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["203.0.113.0/24"]

  instance_types   = ["t3.large"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 6
  min_size         = 3
  max_size         = 12

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}

# Staging Environment
module "staging_k8s" {
  source = "./modules/eks"

  cluster_name       = "staging-k8s"
  kubernetes_version = "1.28"

  private_subnet_ids = module.staging_vpc.private_subnet_ids
  public_subnet_ids  = module.staging_vpc.public_subnet_ids

  # Staging configuration
  instance_types   = ["t3.medium"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 3
  min_size         = 2
  max_size         = 6

  tags = {
    Environment = "staging"
    Purpose     = "testing"
  }
}

# Development Environment
module "dev_k8s" {
  source = "./modules/eks"

  cluster_name       = "dev-k8s"
  kubernetes_version = "1.28"

  private_subnet_ids = module.dev_vpc.private_subnet_ids
  public_subnet_ids  = module.dev_vpc.public_subnet_ids

  # Development configuration with cost optimization
  instance_types   = ["t3.medium"]
  capacity_type    = "SPOT"
  desired_capacity = 2
  min_size         = 1
  max_size         = 4

  tags = {
    Environment  = "development"
    AutoShutdown = "enabled"
    CostCenter   = "engineering"
  }
}
*/

# Example 6: EKS Cluster for Machine Learning Workloads
/*
module "ml_eks" {
  source = "./modules/eks"

  cluster_name       = "ml-cluster"
  kubernetes_version = "1.28"

  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # GPU-enabled instances for ML workloads
  instance_types   = ["p3.2xlarge", "p3.8xlarge"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 2
  min_size         = 0
  max_size         = 10

  tags = {
    Environment = "production"
    Workload    = "machine-learning"
    Team        = "data-science"
    GPU         = "enabled"
  }
}
*/

# Example 7: EKS Cluster with Mixed Instance Types
/*
module "mixed_eks" {
  source = "./modules/eks"

  cluster_name       = "mixed-cluster"
  kubernetes_version = "1.28"

  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # Mixed instance types for different workloads
  instance_types = [
    "t3.medium",   # General purpose
    "t3.large",    # General purpose
    "c5.large",    # Compute optimized
    "r5.large"     # Memory optimized
  ]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 5
  min_size         = 2
  max_size         = 20

  tags = {
    Environment = "production"
    Workload    = "mixed"
    Team        = "platform"
    Scaling     = "auto"
  }
}
*/

# Example 8: EKS Cluster for Microservices Architecture
/*
module "microservices_eks" {
  source = "./modules/eks"

  cluster_name       = "microservices-k8s"
  kubernetes_version = "1.28"

  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  # API server access configuration
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs = [
    "203.0.113.0/24",  # Office
    "198.51.100.0/24"  # CI/CD
  ]

  # Optimized for microservices
  instance_types   = ["t3.large"]
  capacity_type    = "ON_DEMAND"
  desired_capacity = 8
  min_size         = 4
  max_size         = 20

  tags = {
    Environment  = "production"
    Architecture = "microservices"
    Team         = "platform"
    ServiceMesh  = "istio"
  }
}
*/