# ============================================================================
# AWS EFS MODULE OUTPUTS
# ============================================================================
# Output values for EFS file system attributes and endpoints
# Used for integration with other modules and external references
# ============================================================================

# ============================================================================
# FILE SYSTEM IDENTIFICATION
# ============================================================================

output "file_system_id" {
  description = "ID of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].id : null
}

output "file_system_arn" {
  description = "ARN of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].arn : null
}

output "creation_token" {
  description = "Creation token of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].creation_token : null
}

# ============================================================================
# FILE SYSTEM ENDPOINTS
# ============================================================================

output "dns_name" {
  description = "DNS name of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].dns_name : null
}

output "regional_dns_name" {
  description = "Regional DNS name of the EFS file system"
  value       = var.create_file_system ? "${aws_efs_file_system.this[0].id}.efs.${data.aws_region.current.name}.amazonaws.com" : null
}

# ============================================================================
# MOUNT TARGET INFORMATION
# ============================================================================

output "mount_target_ids" {
  description = "List of EFS mount target IDs"
  value       = var.create_file_system ? aws_efs_mount_target.this[*].id : []
}

output "mount_target_dns_names" {
  description = "List of EFS mount target DNS names"
  value       = var.create_file_system ? aws_efs_mount_target.this[*].dns_name : []
}

output "mount_target_ip_addresses" {
  description = "List of EFS mount target IP addresses"
  value       = var.create_file_system ? aws_efs_mount_target.this[*].ip_address : []
}

output "mount_target_network_interface_ids" {
  description = "List of EFS mount target network interface IDs"
  value       = var.create_file_system ? aws_efs_mount_target.this[*].network_interface_id : []
}

output "mount_target_availability_zones" {
  description = "List of availability zones where mount targets are created"
  value       = var.create_file_system ? aws_efs_mount_target.this[*].availability_zone_name : []
}

# ============================================================================
# SECURITY GROUP INFORMATION
# ============================================================================

output "security_group_id" {
  description = "ID of the EFS security group"
  value       = var.create_file_system ? aws_security_group.efs[0].id : null
}

output "security_group_arn" {
  description = "ARN of the EFS security group"
  value       = var.create_file_system ? aws_security_group.efs[0].arn : null
}

output "security_group_name" {
  description = "Name of the EFS security group"
  value       = var.create_file_system ? aws_security_group.efs[0].name : null
}

# ============================================================================
# ACCESS POINTS INFORMATION
# ============================================================================

output "access_point_ids" {
  description = "Map of access point names to their IDs"
  value = var.create_file_system ? {
    for name, ap in aws_efs_access_point.this : name => ap.id
  } : {}
}

output "access_point_arns" {
  description = "Map of access point names to their ARNs"
  value = var.create_file_system ? {
    for name, ap in aws_efs_access_point.this : name => ap.arn
  } : {}
}

output "access_point_file_system_arns" {
  description = "Map of access point names to their file system ARNs"
  value = var.create_file_system ? {
    for name, ap in aws_efs_access_point.this : name => ap.file_system_arn
  } : {}
}

# ============================================================================
# FILE SYSTEM CONFIGURATION
# ============================================================================

output "performance_mode" {
  description = "Performance mode of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].performance_mode : null
}

output "throughput_mode" {
  description = "Throughput mode of the EFS file system"
  value       = var.create_file_system ? aws_efs_file_system.this[0].throughput_mode : null
}

output "provisioned_throughput_in_mibps" {
  description = "Provisioned throughput of the EFS file system in MiB/s"
  value       = var.create_file_system ? aws_efs_file_system.this[0].provisioned_throughput_in_mibps : null
}

output "encrypted" {
  description = "Whether the EFS file system is encrypted"
  value       = var.create_file_system ? aws_efs_file_system.this[0].encrypted : null
}

output "kms_key_id" {
  description = "KMS key ID used for encryption"
  value       = var.create_file_system ? aws_efs_file_system.this[0].kms_key_id : null
}

# ============================================================================
# BACKUP CONFIGURATION
# ============================================================================

output "backup_policy_status" {
  description = "Status of the EFS backup policy"
  value       = var.create_file_system && var.backup_enabled ? aws_efs_backup_policy.this[0].backup_policy[0].status : null
}

# ============================================================================
# REPLICATION INFORMATION
# ============================================================================

output "replication_configuration_id" {
  description = "ID of the EFS replication configuration"
  value       = var.create_file_system && var.replication_configuration != null ? aws_efs_replication_configuration.this[0].id : null
}

output "replication_destination_region" {
  description = "Destination region for EFS replication"
  value       = var.replication_configuration != null ? var.replication_configuration.destination_region : null
}

# ============================================================================
# MOUNT COMMANDS AND INTEGRATION
# ============================================================================

output "mount_command_nfs" {
  description = "NFS mount command for the EFS file system"
  value = var.create_file_system ? "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,intr,timeo=600,retrans=2 ${aws_efs_file_system.this[0].dns_name}:/ /mnt/efs" : null
}

output "mount_command_efs_utils" {
  description = "EFS utils mount command for the EFS file system"
  value = var.create_file_system ? "sudo mount -t efs ${aws_efs_file_system.this[0].id}:/ /mnt/efs" : null
}

output "mount_command_efs_utils_encrypted" {
  description = "EFS utils mount command with encryption in transit"
  value = var.create_file_system ? "sudo mount -t efs -o tls ${aws_efs_file_system.this[0].id}:/ /mnt/efs" : null
}

# ============================================================================
# COMPLETE FILE SYSTEM ATTRIBUTES
# ============================================================================

output "file_system_attributes" {
  description = "Complete EFS file system attributes for reference"
  value = var.create_file_system ? {
    id                              = aws_efs_file_system.this[0].id
    arn                             = aws_efs_file_system.this[0].arn
    creation_token                  = aws_efs_file_system.this[0].creation_token
    dns_name                        = aws_efs_file_system.this[0].dns_name
    performance_mode                = aws_efs_file_system.this[0].performance_mode
    throughput_mode                 = aws_efs_file_system.this[0].throughput_mode
    provisioned_throughput_in_mibps = aws_efs_file_system.this[0].provisioned_throughput_in_mibps
    encrypted                       = aws_efs_file_system.this[0].encrypted
    kms_key_id                      = aws_efs_file_system.this[0].kms_key_id
    number_of_mount_targets         = aws_efs_file_system.this[0].number_of_mount_targets
    size_in_bytes                   = aws_efs_file_system.this[0].size_in_bytes
  } : null
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_region" "current" {}