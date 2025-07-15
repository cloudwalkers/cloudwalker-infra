# 🔐 IAM Integration Guide

This document explains how all modules have been updated to integrate with the IAM module for secure, enterprise-grade AWS infrastructure.

## 🎯 **Integration Overview**

All modules now support flexible IAM integration patterns:
- **Standalone IAM Creation**: Modules can create their own IAM resources
- **External IAM Integration**: Modules can use IAM resources from the dedicated IAM module
- **Hybrid Approach**: Mix of both patterns based on requirements

## 📋 **Module Integration Details**

### **🖥️ EC2 Module IAM Integration**

#### **New Variables**
```hcl
variable "create_iam_instance_profile" {
  description = "Whether to create IAM instance profile and role"
  type        = bool
  default     = false
}

variable "iam_instance_profile_name" {
  description = "Name of existing IAM instance profile to use"
  type        = string
  default     = null
}

variable "iam_managed_policy_arns" {
  description = "List of managed policy ARNs to attach"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}
```

#### **Usage Patterns**

**Pattern 1: Use IAM Module**
```hcl
module "iam" {
  source = "./modules/iam"
  
  roles = {
    "ec2-role" = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }
  }
}

module "ec2" {
  source = "./modules/ec2"
  
  iam_instance_profile_name = module.iam.instance_profiles["ec2-role"].name
  # ... other configuration
}
```

**Pattern 2: Standalone IAM Creation**
```hcl
module "ec2" {
  source = "./modules/ec2"
  
  create_iam_instance_profile = true
  iam_role_name              = "my-ec2-role"
  iam_managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
  # ... other configuration
}
```

### **🐳 ECS Module IAM Integration**

#### **New Variables**
```hcl
variable "create_iam_roles" {
  description = "Whether to create IAM roles for ECS"
  type        = bool
  default     = false
}

variable "execution_role_arn" {
  description = "ARN of existing ECS execution role"
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN of existing ECS task role"
  type        = string
  default     = null
}
```

#### **Usage Patterns**

**Pattern 1: Use IAM Module**
```hcl
module "iam" {
  source = "./modules/iam"
  
  roles = {
    "ecs-execution-role" = {
      assume_role_policy = local.ecs_assume_role_policy
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      ]
    }
    "ecs-task-role" = {
      assume_role_policy = local.ecs_assume_role_policy
      inline_policies = {
        "s3-access" = jsonencode({
          # Custom policy for application
        })
      }
    }
  }
}

module "ecs" {
  source = "./modules/ecs"
  
  execution_role_arn = module.iam.role_arns["ecs-execution-role"]
  task_role_arn     = module.iam.role_arns["ecs-task-role"]
  # ... other configuration
}
```

**Pattern 2: Standalone IAM Creation**
```hcl
module "ecs" {
  source = "./modules/ecs"
  
  create_iam_roles = true
  execution_role_name = "my-ecs-execution-role"
  task_role_name     = "my-ecs-task-role"
  
  execution_role_managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  
  task_role_inline_policies = {
    "app-permissions" = jsonencode({
      # Custom application policies
    })
  }
  # ... other configuration
}
```

### **☸️ EKS Module IAM Integration**

#### **New Variables**
```hcl
variable "create_iam_roles" {
  description = "Whether to create IAM roles for EKS"
  type        = bool
  default     = false
}

variable "cluster_service_role_arn" {
  description = "ARN of existing EKS cluster service role"
  type        = string
  default     = null
}

variable "node_group_role_arn" {
  description = "ARN of existing EKS node group role"
  type        = string
  default     = null
}
```

#### **Usage Patterns**

**Pattern 1: Use IAM Module**
```hcl
module "iam" {
  source = "./modules/iam"
  
  roles = {
    "eks-cluster-role" = {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = { Service = "eks.amazonaws.com" }
        }]
      })
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      ]
    }
    "eks-node-group-role" = {
      assume_role_policy = local.ec2_assume_role_policy
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
    }
  }
}

module "eks" {
  source = "./modules/eks"
  
  cluster_service_role_arn = module.iam.role_arns["eks-cluster-role"]
  node_group_role_arn     = module.iam.role_arns["eks-node-group-role"]
  # ... other configuration
}
```

### **💾 Storage Module IAM Integration**

#### **New Variables**
```hcl
variable "create_s3_access_role" {
  description = "Whether to create IAM role for S3 access"
  type        = bool
  default     = false
}

variable "s3_access_principals" {
  description = "List of principals that can assume the S3 access role"
  type        = list(string)
  default     = []
}
```

#### **Usage Pattern**
```hcl
module "storage" {
  source = "./modules/storage"
  
  create_s3_bucket      = true
  s3_bucket_name        = "my-app-storage"
  
  create_s3_access_role = true
  s3_access_principals = [
    module.iam.role_arns["ec2-instance-role"],
    module.iam.role_arns["ecs-task-role"]
  ]
  # ... other configuration
}
```

## 🏗️ **Complete Integration Example**

The `examples/complete-stack` demonstrates full integration:

```hcl
# 1. Create IAM resources centrally
module "iam" {
  source = "./modules/iam"
  
  roles = {
    "ec2-instance-role"   = { /* EC2 role config */ }
    "ecs-execution-role"  = { /* ECS execution role config */ }
    "ecs-task-role"      = { /* ECS task role config */ }
    "eks-cluster-role"   = { /* EKS cluster role config */ }
    "eks-node-group-role" = { /* EKS node group role config */ }
  }
  
  policies = {
    "s3-app-access" = { /* Custom S3 policy */ }
  }
  
  users = {
    "app-user" = { /* Application user config */ }
  }
}

# 2. Use IAM resources in other modules
module "ec2" {
  source = "./modules/ec2"
  iam_instance_profile_name = module.iam.instance_profiles["ec2-instance-role"].name
}

module "ecs" {
  source = "./modules/ecs"
  execution_role_arn = module.iam.role_arns["ecs-execution-role"]
  task_role_arn     = module.iam.role_arns["ecs-task-role"]
}

module "eks" {
  source = "./modules/eks"
  cluster_service_role_arn = module.iam.role_arns["eks-cluster-role"]
  node_group_role_arn     = module.iam.role_arns["eks-node-group-role"]
}

module "storage" {
  source = "./modules/storage"
  create_s3_access_role = true
  s3_access_principals = [
    module.iam.role_arns["ec2-instance-role"],
    module.iam.role_arns["ecs-task-role"]
  ]
}
```

## 🔄 **Migration Guide**

### **From Standalone to IAM Module Integration**

**Before (Standalone)**
```hcl
module "ec2" {
  source = "./modules/ec2"
  # IAM resources created automatically
}
```

**After (IAM Module Integration)**
```hcl
module "iam" {
  source = "./modules/iam"
  roles = {
    "ec2-role" = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      managed_policy_arns = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }
  }
}

module "ec2" {
  source = "./modules/ec2"
  iam_instance_profile_name = module.iam.instance_profiles["ec2-role"].name
}
```

## 🧪 **Testing Integration**

### **Unit Tests**
Each module includes tests for both integration patterns:

```bash
# Test standalone IAM creation
go test -v -run TestEC2ModuleWithIAM ./...

# Test IAM module integration
go test -v -run TestCompleteStackIntegration ./...
```

### **Integration Tests**
The complete stack test validates:
- ✅ IAM roles are created correctly
- ✅ Modules use the correct IAM resources
- ✅ Cross-module IAM integration works
- ✅ Security policies are applied properly

## 🔒 **Security Benefits**

### **Centralized IAM Management**
- **Single Source of Truth**: All IAM resources defined in one place
- **Consistent Policies**: Standardized role and policy definitions
- **Easier Auditing**: Centralized IAM resource management
- **Policy Reuse**: Share IAM resources across multiple modules

### **Least Privilege Access**
- **Granular Permissions**: Fine-tuned access controls
- **Service-Specific Roles**: Dedicated roles for each service
- **Custom Policies**: Application-specific permission sets
- **Cross-Account Access**: Secure multi-account architectures

### **Compliance & Governance**
- **Policy Validation**: Comprehensive input validation
- **Tagging Standards**: Consistent resource tagging
- **Access Reviews**: Easy identification of permissions
- **Audit Trails**: Clear IAM resource relationships

## 📈 **Best Practices**

### **1. Use IAM Module for Complex Scenarios**
- Multiple services sharing roles
- Custom policies and complex permissions
- Cross-account access requirements
- Centralized IAM governance

### **2. Use Standalone for Simple Cases**
- Single-service deployments
- Standard AWS managed policies only
- Quick prototyping and testing
- Isolated environments

### **3. Hybrid Approach**
- Core services use IAM module
- Auxiliary services use standalone
- Gradual migration strategy
- Environment-specific patterns

## 🚀 **Next Steps**

1. **Review Current Infrastructure**: Identify IAM integration opportunities
2. **Plan Migration**: Choose integration patterns for each module
3. **Test Integration**: Validate with non-production environments
4. **Implement Gradually**: Migrate services incrementally
5. **Monitor & Optimize**: Continuously improve IAM configurations

This IAM integration provides a solid foundation for secure, scalable, and maintainable AWS infrastructure with enterprise-grade identity and access management.