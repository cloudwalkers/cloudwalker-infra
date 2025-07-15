
# ============================================================================
# IAM RESOURCES
# ============================================================================
# These resources create IAM roles and instance profiles for EC2 instances
# when create_iam_instance_profile is enabled. This provides secure access
# to AWS services without embedding credentials in the instances.
# ============================================================================

# IAM Role for EC2 Instances
# This role allows EC2 instances to assume permissions to access AWS services
# The assume_role_policy defines that only EC2 service can assume this role
# This follows AWS security best practices for service-to-service authentication
resource "aws_iam_role" "this" {
  count = var.create_iam_instance_profile ? 1 : 0

  name = var.iam_role_name != null ? var.iam_role_name : "${var.name_prefix}-ec2-role"
  path = "/"
  
  description = "IAM role for EC2 instances in ${var.name_prefix} Auto Scaling Group"

  # Trust policy - defines who can assume this role
  # Only EC2 service can assume this role for security
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = data.aws_region.current.name
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = var.iam_role_name != null ? var.iam_role_name : "${var.name_prefix}-ec2-role"
    Purpose     = "EC2 instance role for Auto Scaling Group"
    ManagedBy   = "terraform"
    Module      = "ec2"
  })
}

# Data source to get current AWS region
data "aws_region" "current" {}

# IAM Managed Policy Attachments
# Attaches AWS managed policies to the EC2 role
# These provide pre-defined permissions for common AWS services
# Examples: SSM access, CloudWatch agent permissions, etc.
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.create_iam_instance_profile ? toset(var.iam_managed_policy_arns) : []

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# IAM Inline Policies
# Custom policies attached directly to the role
# Used for application-specific permissions that don't exist as managed policies
# These policies are deleted when the role is deleted
resource "aws_iam_role_policy" "inline" {
  for_each = var.create_iam_instance_profile ? var.iam_inline_policies : {}

  name   = each.key
  role   = aws_iam_role.this[0].id
  policy = each.value
}

# IAM Instance Profile
# Container for IAM role that can be attached to EC2 instances
# This is what actually gets attached to the EC2 instances
# Allows instances to assume the IAM role and access AWS services
resource "aws_iam_instance_profile" "this" {
  count = var.create_iam_instance_profile ? 1 : 0

  name = var.iam_role_name != null ? var.iam_role_name : "${var.name_prefix}-ec2-profile"
  path = "/"
  role = aws_iam_role.this[0].name

  tags = merge(var.tags, {
    Name      = var.iam_role_name != null ? var.iam_role_name : "${var.name_prefix}-ec2-profile"
    Purpose   = "Instance profile for EC2 Auto Scaling Group"
    ManagedBy = "terraform"
    Module    = "ec2"
  })
}

# ============================================================================
# COMPUTE RESOURCES
# ============================================================================
# These resources define the compute infrastructure including launch templates
# and auto scaling groups. The launch template defines the instance configuration
# while the auto scaling group manages the lifecycle and scaling of instances.
# ============================================================================

# EC2 Launch Template
# Defines the configuration template for EC2 instances in the Auto Scaling Group
# This includes AMI, instance type, security groups, storage, and IAM configuration
# Launch templates provide versioning and advanced features compared to launch configurations
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  description = "Launch template for ${var.name_prefix} Auto Scaling Group"

  # Security Groups
  # Defines network security rules for the instances
  vpc_security_group_ids = var.security_group_ids

  # Block Device Mappings (EBS Volumes)
  # Configures storage volumes attached to instances
  # Supports encryption, volume types, and lifecycle management
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_size           = block_device_mappings.value.volume_size
        volume_type           = block_device_mappings.value.volume_type
        encrypted             = block_device_mappings.value.encrypted
        delete_on_termination = block_device_mappings.value.delete_on_termination
      }
    }
  }

  # IAM Instance Profile
  # Attaches IAM role to instances for AWS service access
  # Only included if IAM integration is enabled
  dynamic "iam_instance_profile" {
    for_each = var.create_iam_instance_profile || var.iam_instance_profile_name != null ? [1] : []
    content {
      name = var.create_iam_instance_profile ? aws_iam_instance_profile.this[0].name : var.iam_instance_profile_name
    }
  }

  # User Data Script
  # Base64-encoded script that runs on instance startup
  # Used for instance initialization and configuration
  user_data = var.user_data_base64

  # Instance Tags
  # Tags applied to EC2 instances when launched
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name      = "${var.name_prefix}-instance"
      Purpose   = "Auto Scaling Group instance"
      ManagedBy = "terraform"
      Module    = "ec2"
    })
  }

  # Volume Tags
  # Tags applied to EBS volumes attached to instances
  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Name      = "${var.name_prefix}-volume"
      Purpose   = "Auto Scaling Group volume"
      ManagedBy = "terraform"
      Module    = "ec2"
    })
  }

  # Launch Template Tags
  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-launch-template"
    Purpose   = "Launch template for Auto Scaling Group"
    ManagedBy = "terraform"
    Module    = "ec2"
  })

  # Lifecycle Management
  # Ensures new launch template is created before destroying old one
  # Prevents downtime during updates
  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
# Manages the lifecycle and scaling of EC2 instances across multiple AZs
# Automatically replaces unhealthy instances and scales based on demand
# Integrates with load balancers for high availability applications
resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}-asg"
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  
  # Subnet Configuration
  # Distributes instances across multiple subnets/AZs for high availability
  vpc_zone_identifier = var.subnet_ids

  # Health Check Configuration
  # Determines how ASG checks instance health (EC2 or ELB)
  # Grace period allows time for instance initialization before health checks
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  # Launch Template Configuration
  # References the launch template that defines instance configuration
  # Version can be $Latest, $Default, or specific version number
  launch_template {
    id      = aws_launch_template.this.id
    version = var.launch_template_version
  }

  # Load Balancer Integration
  # Automatically registers instances with target groups
  # Enables load balancer health checks when target groups are specified
  target_group_arns = var.target_group_arns

  # Instance Refresh Configuration
  # Enables zero-downtime rolling updates of instances
  # Gradually replaces instances with new launch template versions
  dynamic "instance_refresh" {
    for_each = var.enable_instance_refresh ? [1] : []
    content {
      strategy = "Rolling"
      preferences {
        min_healthy_percentage = var.instance_refresh_min_healthy_percentage
        instance_warmup        = var.instance_refresh_instance_warmup
      }
    }
  }

  # Termination Policies
  # Defines which instances to terminate first during scale-down events
  # Options: Default, OldestInstance, NewestInstance, etc.
  termination_policies = var.termination_policies

  # Force Delete Configuration
  # Allows ASG deletion without waiting for instances to drain
  # Use with caution in production environments
  force_delete = var.force_delete

  # Capacity Timeout
  # Maximum time to wait for desired capacity to be reached
  wait_for_capacity_timeout = var.wait_for_capacity_timeout

  # Dynamic Tags
  # Applies user-defined tags to the ASG and optionally to instances
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = var.propagate_tags_at_launch
    }
  }

  # Static Name Tag
  # Always applied to the ASG itself (not propagated to instances)
  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-asg"
    propagate_at_launch = false
  }

  # Additional Management Tags
  tag {
    key                 = "Purpose"
    value               = "Auto Scaling Group for ${var.name_prefix}"
    propagate_at_launch = false
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = false
  }

  tag {
    key                 = "Module"
    value               = "ec2"
    propagate_at_launch = false
  }

  # Lifecycle Management
  # Prevents destruction during updates and ignores manual capacity changes
  lifecycle {
    create_before_destroy = true
    ignore_changes       = [desired_capacity]
  }
}

# ============================================================================
# AUTO SCALING POLICIES & MONITORING
# ============================================================================
# These resources implement intelligent auto scaling based on CloudWatch metrics
# Policies define how to scale (up/down) and alarms trigger the scaling actions
# This enables automatic capacity adjustment based on application demand
# ============================================================================

# Scale Up Policy
# Defines how many instances to add when scaling up
# Uses ChangeInCapacity to add a specific number of instances
# Cooldown period prevents rapid successive scaling actions
resource "aws_autoscaling_policy" "scale_up" {
  count = var.enable_scaling_policies ? 1 : 0

  name                   = "${var.name_prefix}-scale-up"
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown              = var.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.this.name
  
  # Policy type determines scaling behavior
  # SimpleScaling: Basic step scaling
  policy_type = "SimpleScaling"
}

# Scale Down Policy
# Defines how many instances to remove when scaling down
# Negative scaling_adjustment reduces capacity
# Longer cooldown prevents aggressive scale-down actions
resource "aws_autoscaling_policy" "scale_down" {
  count = var.enable_scaling_policies ? 1 : 0

  name                   = "${var.name_prefix}-scale-down"
  scaling_adjustment     = var.scale_down_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown              = var.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.this.name
  
  # Policy type for consistent scaling behavior
  policy_type = "SimpleScaling"
}

# High CPU Utilization Alarm
# Monitors average CPU usage across all instances in the ASG
# Triggers scale-up policy when CPU exceeds threshold for specified periods
# Uses 5-minute periods with 2 consecutive breaches to avoid false alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_scaling_policies ? 1 : 0

  alarm_name          = "${var.name_prefix}-cpu-high"
  alarm_description   = "Triggers scale-up when CPU utilization is high for ${var.name_prefix} ASG"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"  # 5 minutes
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  
  # Actions to take when alarm state changes
  alarm_actions = [aws_autoscaling_policy.scale_up[0].arn]
  ok_actions    = []  # No action when returning to normal
  
  # Treat missing data as not breaching (instances might be starting up)
  treat_missing_data = "notBreaching"

  # Dimensions specify which resources to monitor
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-cpu-high-alarm"
    Purpose   = "Auto scaling trigger for high CPU"
    ManagedBy = "terraform"
    Module    = "ec2"
  })
}

# Low CPU Utilization Alarm
# Monitors for sustained low CPU usage to trigger scale-down
# Helps reduce costs by removing unnecessary instances
# More conservative thresholds prevent premature scale-down
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count = var.enable_scaling_policies ? 1 : 0

  alarm_name          = "${var.name_prefix}-cpu-low"
  alarm_description   = "Triggers scale-down when CPU utilization is low for ${var.name_prefix} ASG"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"  # 5 minutes
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  
  # Actions to take when alarm state changes
  alarm_actions = [aws_autoscaling_policy.scale_down[0].arn]
  ok_actions    = []  # No action when returning to normal
  
  # Treat missing data as not breaching (conservative approach)
  treat_missing_data = "notBreaching"

  # Dimensions specify which resources to monitor
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.this.name
  }

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-cpu-low-alarm"
    Purpose   = "Auto scaling trigger for low CPU"
    ManagedBy = "terraform"
    Module    = "ec2"
  })
}