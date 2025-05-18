module "vpc" {
    source = "./modules/vpc"
    
    # VPC and networking
    vpc_cidr_block       = var.vpc_cidr_block
    public_subnet_cidrs  = var.public_subnet_cidrs
    private_subnet_cidrs = var.private_subnet_cidrs
    
    # Security group details
    allowed_ips          = var.allowed_ips
  
}