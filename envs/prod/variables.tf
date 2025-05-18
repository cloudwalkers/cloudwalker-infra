variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "domain_name" {}
variable "hosted_zone_id" {}