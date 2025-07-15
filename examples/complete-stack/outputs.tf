# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

# IAM Outputs
output "iam_role_arns" {
  description = "ARNs of all IAM roles"
  value       = module.iam.role_arns
}

output "iam_policy_arns" {
  description = "ARNs of all IAM policies"
  value       = module.iam.policy_arns
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = module.iam.instance_profiles["ec2-instance-role"].name
}

# Storage Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.storage.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.storage.s3_bucket_arn
}

output "efs_id" {
  description = "ID of the EFS file system"
  value       = module.storage.efs_id
}

output "efs_dns_name" {
  description = "DNS name of the EFS file system"
  value       = module.storage.efs_dns_name
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.load_balancer_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.load_balancer_zone_id
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = module.alb.target_group_arns
}

# EC2 Outputs
output "ec2_autoscaling_group_name" {
  description = "Name of the EC2 Auto Scaling Group"
  value       = module.ec2.autoscaling_group_name
}

output "ec2_launch_template_id" {
  description = "ID of the EC2 launch template"
  value       = module.ec2.launch_template_id
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

# EKS Outputs
output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# Integration Information
output "integration_summary" {
  description = "Summary of how modules are integrated"
  value = {
    vpc_cidr                = module.vpc.vpc_cidr_block
    ec2_instance_profile    = module.iam.instance_profiles["ec2-instance-role"].name
    ecs_execution_role      = module.iam.role_arns["ecs-execution-role"]
    ecs_task_role          = module.iam.role_arns["ecs-task-role"]
    eks_cluster_role       = module.iam.role_arns["eks-cluster-role"]
    eks_node_group_role    = module.iam.role_arns["eks-node-group-role"]
    s3_bucket              = module.storage.s3_bucket_id
    efs_file_system        = module.storage.efs_id
    load_balancer_dns      = module.alb.load_balancer_dns_name
  }
}