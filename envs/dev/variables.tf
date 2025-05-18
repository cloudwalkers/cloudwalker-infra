variable "vpc_id" {}
variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "domain_name" {}
variable "hosted_zone_id" {}
variable "aws_region" {
  default = "us-east-1"
}
variable "tags" {
  type = map(string)
  default = {
    Name        = "cloudwalker"
    Environment = "${var.env}-main"
    Project     = "cloudwalker"
  }
}