# ============================================================================
# EKS CLUSTER RESOURCES
# ============================================================================
# Amazon EKS provides managed Kubernetes control plane
# Handles master node management, API server, etcd, and networking
# Integrates with AWS services for authentication, authorization, and logging
# ============================================================================

# EKS Cluster
# Managed Kubernetes control plane that runs the Kubernetes API server
# Provides highly available, secure, and scalable Kubernetes environment
# Automatically manages master nodes, patches, and updates
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.create_iam_roles ? aws_iam_role.eks_cluster[0].arn : var.cluster_service_role_arn
  version  = var.kubernetes_version

  # VPC Configuration
  # Defines networking settings for the EKS cluster
  # Controls API server endpoint access and subnet placement
  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = var.endpoint_private_access  # Private VPC access to API server
    endpoint_public_access  = var.endpoint_public_access   # Public internet access to API server
    public_access_cidrs     = var.public_access_cidrs      # CIDR blocks allowed for public access
  }

  # Dependencies
  # Ensures IAM roles and policies are in place before cluster creation
  depends_on = var.create_iam_roles ? [
    aws_iam_role_policy_attachment.eks_cluster_managed,
    aws_iam_role_policy.eks_cluster_inline,
  ] : []

  tags = merge(var.tags, {
    Name      = var.cluster_name
    Purpose   = "EKS cluster for Kubernetes workloads"
    ManagedBy = "terraform"
    Module    = "eks"
  })
}

# ============================================================================
# EKS CLUSTER IAM RESOURCES (OPTIONAL)
# ============================================================================
# IAM roles provide the necessary permissions for EKS cluster operations
# Cluster service role: Used by EKS control plane for AWS API calls
# Includes permissions for networking, logging, and cluster management
# ============================================================================

# EKS Cluster Service Role
# Used by the EKS control plane to make AWS API calls on your behalf
# Required for cluster operations like managing ENIs, security groups, and logs
# Must have AmazonEKSClusterPolicy attached at minimum
resource "aws_iam_role" "eks_cluster" {
  count = var.create_iam_roles ? 1 : 0

  name = var.cluster_service_role_name != null ? var.cluster_service_role_name : "${var.cluster_name}-cluster-role"
  path = "/"
  description = "EKS cluster service role for ${var.cluster_name}"

  # Trust Policy - EKS Service
  # Allows EKS service to assume this role for cluster operations
  # Required for EKS control plane functionality
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = var.cluster_service_role_name != null ? var.cluster_service_role_name : "${var.cluster_name}-cluster-role"
    Purpose   = "EKS cluster service role"
    ManagedBy = "terraform"
    Module    = "eks"
  })
}

# EKS Cluster Managed Policy Attachments
# Attaches AWS managed policies required for EKS cluster operations
# AmazonEKSClusterPolicy provides essential cluster management permissions
resource "aws_iam_role_policy_attachment" "eks_cluster_managed" {
  for_each = var.create_iam_roles ? toset(var.cluster_service_role_managed_policy_arns) : []

  policy_arn = each.value
  role       = aws_iam_role.eks_cluster[0].name
}

# EKS Cluster Inline Policies
# Custom policies for specific cluster requirements
# Used for additional permissions beyond standard managed policies
resource "aws_iam_role_policy" "eks_cluster_inline" {
  for_each = var.create_iam_roles ? var.cluster_service_role_inline_policies : {}

  name   = each.key
  role   = aws_iam_role.eks_cluster[0].id
  policy = each.value
}

# ============================================================================
# EKS NODE GROUP RESOURCES
# ============================================================================
# EKS Node Groups provide managed EC2 instances for running Kubernetes pods
# Handles instance lifecycle, auto scaling, and integration with EKS cluster
# Supports both On-Demand and Spot instances for cost optimization
# ============================================================================

# EKS Node Group
# Managed group of EC2 instances that serve as Kubernetes worker nodes
# Automatically joins the EKS cluster and handles node lifecycle management
# Provides auto scaling and self-healing capabilities
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.create_iam_roles ? aws_iam_role.eks_node_group[0].arn : var.node_group_role_arn
  subnet_ids      = var.private_subnet_ids  # Deploy in private subnets for security

  # Capacity Configuration
  # Defines the type of instances and purchasing options
  capacity_type  = var.capacity_type   # ON_DEMAND or SPOT for cost optimization
  instance_types = var.instance_types  # List of instance types for flexibility

  # Auto Scaling Configuration
  # Defines the number of nodes in the group
  # EKS automatically distributes nodes across AZs
  scaling_config {
    desired_size = var.desired_capacity  # Target number of nodes
    max_size     = var.max_size         # Maximum nodes for scaling up
    min_size     = var.min_size         # Minimum nodes for high availability
  }

  # Update Configuration
  # Controls how nodes are updated during cluster upgrades
  # max_unavailable ensures some nodes remain available during updates
  update_config {
    max_unavailable = 1  # Maximum nodes that can be unavailable during updates
  }

  # Dependencies
  # Ensures IAM roles and policies are configured before node group creation
  depends_on = var.create_iam_roles ? [
    aws_iam_role_policy_attachment.eks_node_group_managed,
    aws_iam_role_policy.eks_node_group_inline,
  ] : []

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-nodes"
    Purpose   = "EKS node group for worker nodes"
    ManagedBy = "terraform"
    Module    = "eks"
  })
}

# ============================================================================
# EKS NODE GROUP IAM RESOURCES (OPTIONAL)
# ============================================================================
# IAM roles provide necessary permissions for EKS worker nodes
# Node group role: Used by EC2 instances to join EKS cluster and pull images
# Includes permissions for container registry, CNI, and worker node operations
# ============================================================================

# EKS Node Group Role
# Used by EC2 instances in the node group to join the EKS cluster
# Required for worker nodes to register with the cluster and run pods
# Must have specific EKS worker node policies attached
resource "aws_iam_role" "eks_node_group" {
  count = var.create_iam_roles ? 1 : 0

  name = var.node_group_role_name != null ? var.node_group_role_name : "${var.cluster_name}-node-group-role"
  path = "/"
  description = "EKS node group role for worker nodes in ${var.cluster_name}"

  # Trust Policy - EC2 Service
  # Allows EC2 instances to assume this role
  # Required for worker nodes to access AWS services
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = var.node_group_role_name != null ? var.node_group_role_name : "${var.cluster_name}-node-group-role"
    Purpose   = "EKS node group role for worker nodes"
    ManagedBy = "terraform"
    Module    = "eks"
  })
}

# EKS Node Group Managed Policy Attachments
# Attaches AWS managed policies required for EKS worker nodes
# Standard policies: AmazonEKSWorkerNodePolicy, AmazonEKS_CNI_Policy, AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "eks_node_group_managed" {
  for_each = var.create_iam_roles ? toset(var.node_group_role_managed_policy_arns) : []

  policy_arn = each.value
  role       = aws_iam_role.eks_node_group[0].name
}

# EKS Node Group Inline Policies
# Custom policies for specific worker node requirements
# Used for additional permissions like accessing ECR, CloudWatch, or other AWS services
resource "aws_iam_role_policy" "eks_node_group_inline" {
  for_each = var.create_iam_roles ? var.node_group_role_inline_policies : {}

  name   = each.key
  role   = aws_iam_role.eks_node_group[0].id
  policy = each.value
}