module "compute" {
  source             = "../../../modules/compute"
  providers          = { aws = aws }

  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids

  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.key_name

  domain_name        = var.domain_name
  hosted_zone_id     = var.hosted_zone_id

  desired_capacity   = 3
  min_size           = 3
  max_size           = 3
  health_check_path  = "/"
}
# This module creates a VPC with public and private subnets, security groups, and route tables.
# It also creates an Internet Gateway and a NAT Gateway for outbound internet access from private subnets.
module "vpc" {
  source                = "../../../modules/vpc"
  providers             = { aws = aws }

  vpc_cidr_block        = var.vpc_cidr_block
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs

  allowed_ips           = var.allowed_ips
  tags                 = {
    Name        = "cloudwalker"
    Environment = "${var.env}-main"
    Project     = "cloudwalker"
  }
}