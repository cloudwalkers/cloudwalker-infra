variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.cluster_name))
    error_message = "Cluster name must contain only alphanumeric characters and hyphens."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Kubernetes version must be in format X.Y (e.g., 1.28)."
  }
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least 2 private subnets are required for EKS."
  }
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the EKS cluster"
  type        = list(string)
  default     = []
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type must be either ON_DEMAND or SPOT."
  }
}

variable "instance_types" {
  description = "List of instance types for the EKS Node Group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_capacity" {
  description = "Desired number of nodes in the EKS Node Group"
  type        = number
  default     = 2
  validation {
    condition     = var.desired_capacity >= 1
    error_message = "Desired capacity must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of nodes in the EKS Node Group"
  type        = number
  default     = 4
  validation {
    condition     = var.max_size >= 1
    error_message = "Maximum size must be at least 1."
  }
}

variable "min_size" {
  description = "Minimum number of nodes in the EKS Node Group"
  type        = number
  default     = 1
  validation {
    condition     = var.min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

# IAM Configuration
variable "create_iam_roles" {
  description = "Whether to create IAM roles for EKS"
  type        = bool
  default     = false
}

variable "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role (if not creating)"
  type        = string
  default     = null
}

variable "node_group_role_arn" {
  description = "ARN of the EKS node group role (if not creating)"
  type        = string
  default     = null
}

variable "cluster_service_role_name" {
  description = "Name for the EKS cluster service role (if creating)"
  type        = string
  default     = null
}

variable "node_group_role_name" {
  description = "Name for the EKS node group role (if creating)"
  type        = string
  default     = null
}

variable "cluster_service_role_managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the cluster service role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
}

variable "node_group_role_managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the node group role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}

variable "cluster_service_role_inline_policies" {
  description = "Map of inline policies to attach to the cluster service role"
  type        = map(string)
  default     = {}
}

variable "node_group_role_inline_policies" {
  description = "Map of inline policies to attach to the node group role"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}