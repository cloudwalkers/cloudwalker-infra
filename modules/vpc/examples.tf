# Example 1: Basic VPC for Development
/*
module "dev_vpc" {
  source = "./modules/vpc"

  name_prefix             = "dev"
  vpc_cidr_block          = "10.0.0.0/16"
  public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
  allowed_ips             = ["0.0.0.0/0"]

  tags = {
    Environment = "development"
    Project     = "my-app"
    Owner       = "dev-team"
  }
}
*/

# Example 2: Production VPC with Restricted Access
/*
module "prod_vpc" {
  source = "./modules/vpc"

  name_prefix             = "prod"
  vpc_cidr_block          = "10.1.0.0/16"
  public_subnet_cidrs     = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnet_cidrs    = ["10.1.10.0/24", "10.1.20.0/24"]
  
  # Restrict access to office and VPN networks
  allowed_ips = [
    "203.0.113.0/24",    # Office network
    "198.51.100.0/24",   # VPN network
    "192.0.2.0/24"       # Partner network
  ]

  tags = {
    Environment = "production"
    Project     = "my-app"
    Team        = "platform"
    CostCenter  = "engineering"
    Backup      = "required"
  }
}
*/

# Example 3: Large VPC with Multiple Subnets
/*
module "enterprise_vpc" {
  source = "./modules/vpc"

  name_prefix             = "enterprise"
  vpc_cidr_block          = "172.16.0.0/16"
  
  # 3 public subnets across 3 AZs
  public_subnet_cidrs = [
    "172.16.1.0/24",
    "172.16.2.0/24",
    "172.16.3.0/24"
  ]
  
  # 3 private subnets across 3 AZs
  private_subnet_cidrs = [
    "172.16.10.0/24",
    "172.16.20.0/24",
    "172.16.30.0/24"
  ]
  
  allowed_ips = ["172.16.0.0/16"]  # Only internal traffic

  tags = {
    Environment = "production"
    Application = "enterprise-app"
    Team        = "platform"
    Compliance  = "required"
  }
}
*/

# Example 4: Staging VPC with Custom CIDR
/*
module "staging_vpc" {
  source = "./modules/vpc"

  name_prefix             = "staging"
  vpc_cidr_block          = "192.168.0.0/16"
  public_subnet_cidrs     = ["192.168.1.0/24", "192.168.2.0/24"]
  private_subnet_cidrs    = ["192.168.10.0/24", "192.168.20.0/24"]
  
  # Allow access from dev and prod networks
  allowed_ips = [
    "10.0.0.0/16",      # Dev VPC
    "10.1.0.0/16",      # Prod VPC
    "203.0.113.0/24"    # Office network
  ]

  tags = {
    Environment = "staging"
    Project     = "my-app"
    Purpose     = "testing"
    AutoShutdown = "enabled"
  }
}
*/

# Example 5: Multi-Region VPC Setup
/*
# Primary region VPC
module "primary_vpc" {
  source = "./modules/vpc"

  name_prefix             = "primary"
  vpc_cidr_block          = "10.0.0.0/16"
  public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
  allowed_ips             = ["10.0.0.0/8"]  # Allow all private networks

  tags = {
    Environment = "production"
    Region      = "primary"
    Project     = "multi-region-app"
  }
}

# Secondary region VPC (different CIDR to avoid conflicts)
module "secondary_vpc" {
  source = "./modules/vpc"

  name_prefix             = "secondary"
  vpc_cidr_block          = "10.10.0.0/16"
  public_subnet_cidrs     = ["10.10.1.0/24", "10.10.2.0/24"]
  private_subnet_cidrs    = ["10.10.10.0/24", "10.10.20.0/24"]
  allowed_ips             = ["10.0.0.0/8"]  # Allow all private networks

  tags = {
    Environment = "production"
    Region      = "secondary"
    Project     = "multi-region-app"
  }
}
*/