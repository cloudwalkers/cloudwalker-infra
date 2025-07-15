variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only alphanumeric characters and hyphens."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs where the EC2 instances will be launched"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID is required."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to instances"
  type        = list(string)
  default     = []
}
variable "ami_id" {
  description = "The AMI ID to use for the EC2 instances."
  type        = string
  default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  validation {
    condition     = can(regex("^ami-[a-f0-9]{8}([a-f0-9]{9})?$", var.ami_id))
    error_message = "The AMI ID must be a valid AMI ID format (ami-xxxxxxxx or ami-xxxxxxxxxxxxxxxxx)."
  }
}
variable "instance_type" {
  description = "The instance type for the EC2 instances."
  type        = string
  default     = "t2.micro"
  validation {
    condition     = can(regex("^[a-zA-Z0-9.]+$", var.instance_type))
    error_message = "The instance type must be a valid EC2 instance type."
  }
}
variable "key_name" {
  description = "The name of the key pair to use for SSH access to the EC2 instances."
  type        = string
  default     = "my-key-pair"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.key_name))
    error_message = "The key name must be a valid EC2 key pair name."
  }
  sensitive = true
  # The key name is sensitive information, so we mark it as sensitive.
  # This will prevent it from being displayed in the Terraform plan or apply output.
  # Note: The key name itself is not sensitive, but the value may contain sensitive information.
  # If you are using a key pair that contains sensitive information, you should mark it as sensitive.
  # In this case, we are assuming that the key name is not sensitive, but the value may be.
}

variable "desired_capacity" {
  description = "The desired number of EC2 instances in the Auto Scaling group."
  type        = number
  default     = 3
  validation {
    condition     = var.desired_capacity >= 0 && var.desired_capacity <= 1000
    error_message = "The desired capacity must be between 0 and 1000."
  }
}
variable "min_size" {
  description = "The minimum number of EC2 instances in the Auto Scaling group."
  type        = number
  default     = 1
  validation {
    condition     = var.min_size >= 0 && var.min_size <= 1000
    error_message = "The minimum size must be between 0 and 1000."
  }
}
variable "max_size" {
  description = "The maximum number of EC2 instances in the Auto Scaling group."
  type        = number
  default     = 5
  validation {
    condition     = var.max_size >= 1 && var.max_size <= 1000
    error_message = "The maximum size must be between 1 and 1000."
  }
}
variable "block_device_mappings" {
  description = "List of block device mappings for the launch template"
  type = list(object({
    device_name           = string
    volume_size           = number
    volume_type           = string
    encrypted             = bool
    delete_on_termination = bool
  }))
  default = [
    {
      device_name           = "/dev/xvda"
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  ]
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile to attach to instances"
  type        = string
  default     = null
}

variable "create_iam_instance_profile" {
  description = "Whether to create IAM instance profile and role"
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "Name for the IAM role (if creating)"
  type        = string
  default     = null
}

variable "iam_managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the IAM role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}

variable "iam_inline_policies" {
  description = "Map of inline policies to attach to the IAM role"
  type        = map(string)
  default     = {}
}

variable "user_data_base64" {
  description = "Base64 encoded user data script"
  type        = string
  default     = null
}

variable "health_check_type" {
  description = "Type of health check for Auto Scaling Group"
  type        = string
  default     = "EC2"
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be either EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.health_check_grace_period >= 0 && var.health_check_grace_period <= 7200
    error_message = "Health check grace period must be between 0 and 7200 seconds."
  }
}

variable "launch_template_version" {
  description = "Launch template version to use"
  type        = string
  default     = "$Latest"
}

variable "target_group_arns" {
  description = "List of target group ARNs to attach to the Auto Scaling Group"
  type        = list(string)
  default     = []
}

variable "enable_instance_refresh" {
  description = "Enable instance refresh for the Auto Scaling Group"
  type        = bool
  default     = false
}

variable "instance_refresh_min_healthy_percentage" {
  description = "Minimum healthy percentage during instance refresh"
  type        = number
  default     = 90
  validation {
    condition     = var.instance_refresh_min_healthy_percentage >= 0 && var.instance_refresh_min_healthy_percentage <= 100
    error_message = "Instance refresh min healthy percentage must be between 0 and 100."
  }
}

variable "instance_refresh_instance_warmup" {
  description = "Instance warmup time in seconds during instance refresh"
  type        = number
  default     = 300
}

variable "termination_policies" {
  description = "List of termination policies for the Auto Scaling Group"
  type        = list(string)
  default     = ["Default"]
  validation {
    condition = alltrue([
      for policy in var.termination_policies : contains([
        "Default", "OldestInstance", "NewestInstance", "OldestLaunchConfiguration",
        "OldestLaunchTemplate", "ClosestToNextInstanceHour", "AllocationStrategy"
      ], policy)
    ])
    error_message = "Invalid termination policy specified."
  }
}

variable "force_delete" {
  description = "Allow deletion of Auto Scaling Group without waiting for instances to drain"
  type        = bool
  default     = false
}

variable "wait_for_capacity_timeout" {
  description = "Maximum time to wait for the desired capacity"
  type        = string
  default     = "10m"
}

variable "propagate_tags_at_launch" {
  description = "Whether to propagate tags to instances at launch"
  type        = bool
  default     = true
}

variable "enable_scaling_policies" {
  description = "Enable auto scaling policies and CloudWatch alarms"
  type        = bool
  default     = false
}

variable "scale_up_adjustment" {
  description = "Number of instances to add when scaling up"
  type        = number
  default     = 1
}

variable "scale_down_adjustment" {
  description = "Number of instances to remove when scaling down"
  type        = number
  default     = -1
}

variable "scale_up_cooldown" {
  description = "Cooldown period after scaling up"
  type        = number
  default     = 300
}

variable "scale_down_cooldown" {
  description = "Cooldown period after scaling down"
  type        = number
  default     = 300
}

variable "cpu_high_threshold" {
  description = "CPU threshold for scaling up"
  type        = number
  default     = 80
  validation {
    condition     = var.cpu_high_threshold >= 0 && var.cpu_high_threshold <= 100
    error_message = "CPU high threshold must be between 0 and 100."
  }
}

variable "cpu_low_threshold" {
  description = "CPU threshold for scaling down"
  type        = number
  default     = 20
  validation {
    condition     = var.cpu_low_threshold >= 0 && var.cpu_low_threshold <= 100
    error_message = "CPU low threshold must be between 0 and 100."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}
# Validation to ensure ASG sizing is logical
locals {
  asg_sizing_valid = var.min_size <= var.desired_capacity && var.desired_capacity <= var.max_size
}

variable "validate_asg_sizing" {
  description = "Internal validation for ASG sizing logic"
  type        = bool
  default     = true
  validation {
    condition     = local.asg_sizing_valid
    error_message = "Auto Scaling Group sizing must follow: min_size <= desired_capacity <= max_size."
  }
}