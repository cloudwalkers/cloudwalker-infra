output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.this.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group"
  value       = aws_eks_node_group.this.status
}

# IAM Outputs
output "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = var.create_iam_roles ? aws_iam_role.eks_cluster[0].arn : var.cluster_service_role_arn
}

output "cluster_service_role_name" {
  description = "Name of the EKS cluster service role"
  value       = var.create_iam_roles ? aws_iam_role.eks_cluster[0].name : null
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = var.create_iam_roles ? aws_iam_role.eks_node_group[0].arn : var.node_group_role_arn
}

output "node_group_role_name" {
  description = "Name of the EKS node group role"
  value       = var.create_iam_roles ? aws_iam_role.eks_node_group[0].name : null
}