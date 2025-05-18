variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "domain_name" {}
variable "hosted_zone_id" {}
variable "desired_capacity" { default = 3 }
variable "min_size" { default = 3 }
variable "max_size" { default = 3 }
variable "health_check_path" { default = "/" }
variable "aws_region" {
  default = "us-west-2"
  description = "The AWS region to deploy resources in."
}
