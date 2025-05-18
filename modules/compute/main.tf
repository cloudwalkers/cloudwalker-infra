module "compute" {
  source = "./modules/compute"

  # VPC and networking
  vpc_id               = var.vpc_id
  public_subnet_ids    = var.public_subnet_ids

  # EC2 instance details
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  key_name             = var.key_name

  # Load Balancer and DNS
  domain_name          = var.domain_name
  hosted_zone_id       = var.hosted_zone_id

  # ASG details
  desired_capacity     = 3
  min_size             = 3
  max_size             = 3
  health_check_path    = "/"
}