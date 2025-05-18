module "ec2_alb_asg_r53" {
  source             = "../../modules/compute"
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