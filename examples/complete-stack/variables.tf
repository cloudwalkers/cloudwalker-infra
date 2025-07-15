variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "complete-stack"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-aws-modules"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "platform-team"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "my-key-pair"
}