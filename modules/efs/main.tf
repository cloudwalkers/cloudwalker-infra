# ============================================================================
# AWS EFS (Elastic File System) MODULE
# ============================================================================
# This module creates and manages AWS EFS file systems for shared storage
# across multiple EC2 instances and containers. EFS provides:
# - Fully managed NFS file system with POSIX compliance
# - Automatic scaling from gigabytes to petabytes
# - Multi-AZ availability and durability
# - Encryption at rest and in transit
# - Performance modes for different workload requirements
# - Integration with EC2, ECS, EKS, and Lambda
# ============================================================================

# ============================================================================
# EFS FILE SYSTEM
# ============================================================================
# Primary EFS file system for shared storage
# Provides scalable, managed NFS storage with configurable performance
# Supports encryption, backup, and lifecycle management
resource "aws_efs_file_system" "this" {
  count = var.create_file_system ? 1 : 0

  creation_token                  = var.creation_token != null ? var.creation_token : "${var.name}-${random_string.creation_token[0].result}"
  performance_mode               = var.performance_mode
  throughput_mode                = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput : null
  encrypted                      = var.encrypted
  kms_key_id                     = var.encrypted && var.kms_key_id != null ? var.kms_key_id : null

  # Lifecycle policy for cost optimization
  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy != null ? [var.lifecycle_policy] : []
    content {
      transition_to_ia                    = lifecycle_policy.value.transition_to_ia
      transition_to_primary_storage_class = lifecycle_policy.value.transition_to_primary_storage_class
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = var.name
      Environment = var.environment
      Module      = "efs"
    }
  )
}

# ============================================================================
# RANDOM CREATION TOKEN
# ============================================================================
# Generates unique creation token if not provided
# Ensures EFS file system uniqueness within the region
resource "random_string" "creation_token" {
  count = var.create_file_system && var.creation_token == null ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

# ============================================================================
# EFS MOUNT TARGETS
# ============================================================================
# Mount targets for accessing EFS from different availability zones
# Provides high availability and fault tolerance
# Each subnet gets its own mount target for optimal performance
resource "aws_efs_mount_target" "this" {
  count = var.create_file_system ? length(var.subnet_ids) : 0

  file_system_id  = aws_efs_file_system.this[0].id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs[0].id]

  # Ensure security group is created first
  depends_on = [aws_security_group.efs]
}

# ============================================================================
# EFS SECURITY GROUP
# ============================================================================
# Security group controlling network access to EFS mount targets
# Allows NFS traffic (port 2049) from specified sources
# Essential for secure file system access control
resource "aws_security_group" "efs" {
  count = var.create_file_system ? 1 : 0

  name_prefix = "${var.name}-efs-"
  description = "Security group for EFS mount targets - ${var.name}"
  vpc_id      = var.vpc_id

  # NFS ingress rule - allow access from specified sources
  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      description = "NFS access from CIDR blocks"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # NFS ingress rule - allow access from security groups
  dynamic "ingress" {
    for_each = length(var.allowed_security_group_ids) > 0 ? [1] : []
    content {
      description     = "NFS access from security groups"
      from_port       = 2049
      to_port         = 2049
      protocol        = "tcp"
      security_groups = var.allowed_security_group_ids
    }
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.name}-efs-sg"
      Environment = var.environment
      Module      = "efs"
      Purpose     = "efs-access"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# EFS BACKUP POLICY
# ============================================================================
# Automatic backup configuration using AWS Backup
# Provides point-in-time recovery and compliance
# Integrates with AWS Backup service for centralized backup management
resource "aws_efs_backup_policy" "this" {
  count = var.create_file_system && var.backup_enabled ? 1 : 0

  file_system_id = aws_efs_file_system.this[0].id

  backup_policy {
    status = "ENABLED"
  }
}

# ============================================================================
# EFS ACCESS POINTS
# ============================================================================
# Application-specific access points for fine-grained access control
# Provides POSIX permissions and path-based access
# Enables secure multi-tenant access to shared file systems
resource "aws_efs_access_point" "this" {
  for_each = var.create_file_system ? var.access_points : {}

  file_system_id = aws_efs_file_system.this[0].id

  # POSIX user configuration
  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      gid            = posix_user.value.gid
      uid            = posix_user.value.uid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  # Root directory configuration
  dynamic "root_directory" {
    for_each = each.value.root_directory != null ? [each.value.root_directory] : []
    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []
        content {
          owner_gid   = creation_info.value.owner_gid
          owner_uid   = creation_info.value.owner_uid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name        = "${var.name}-${each.key}"
      Environment = var.environment
      Module      = "efs"
      AccessPoint = each.key
    }
  )
}

# ============================================================================
# EFS FILE SYSTEM POLICY
# ============================================================================
# Resource-based policy for EFS file system access control
# Defines permissions for file system operations
# Supports cross-account access and service integration
resource "aws_efs_file_system_policy" "this" {
  count = var.create_file_system && var.file_system_policy != null ? 1 : 0

  file_system_id                     = aws_efs_file_system.this[0].id
  policy                             = var.file_system_policy
  bypass_policy_lockout_safety_check = var.bypass_policy_lockout_safety_check
}

# ============================================================================
# EFS REPLICATION CONFIGURATION
# ============================================================================
# Cross-region replication for disaster recovery
# Provides automated backup to another AWS region
# Ensures business continuity and data protection
resource "aws_efs_replication_configuration" "this" {
  count = var.create_file_system && var.replication_configuration != null ? 1 : 0

  source_file_system_id = aws_efs_file_system.this[0].id

  destination {
    region                 = var.replication_configuration.destination_region
    availability_zone_name = var.replication_configuration.availability_zone_name
    kms_key_id            = var.replication_configuration.kms_key_id
  }
}