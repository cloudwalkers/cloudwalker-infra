# Local values for policy attachments
locals {
  # User policy attachments
  user_policy_attachments = merge([
    for user_name, user_config in var.users : {
      for policy_arn in user_config.managed_policy_arns : "${user_name}-${replace(policy_arn, "/[^a-zA-Z0-9]/", "-")}" => {
        user       = user_name
        policy_arn = policy_arn
      }
    }
  ]...)

  # User inline policies
  user_inline_policies = merge([
    for user_name, user_config in var.users : {
      for policy_name, policy_document in user_config.inline_policies : "${user_name}-${policy_name}" => {
        user        = user_name
        policy_name = policy_name
        policy      = policy_document
      }
    }
  ]...)

  # Group policy attachments
  group_policy_attachments = merge([
    for group_name, group_config in var.groups : {
      for policy_arn in group_config.managed_policy_arns : "${group_name}-${replace(policy_arn, "/[^a-zA-Z0-9]/", "-")}" => {
        group      = group_name
        policy_arn = policy_arn
      }
    }
  ]...)

  # Group inline policies
  group_inline_policies = merge([
    for group_name, group_config in var.groups : {
      for policy_name, policy_document in group_config.inline_policies : "${group_name}-${policy_name}" => {
        group       = group_name
        policy_name = policy_name
        policy      = policy_document
      }
    }
  ]...)

  # Role policy attachments
  role_policy_attachments = merge([
    for role_name, role_config in var.roles : {
      for policy_arn in role_config.managed_policy_arns : "${role_name}-${replace(policy_arn, "/[^a-zA-Z0-9]/", "-")}" => {
        role       = role_name
        policy_arn = policy_arn
      }
    }
  ]...)

  # Role inline policies (separate from the ones defined in the role resource)
  role_inline_policies = merge([
    for role_name, role_config in var.roles : {
      for policy_name, policy_document in role_config.additional_inline_policies : "${role_name}-${policy_name}" => {
        role        = role_name
        policy_name = policy_name
        policy      = policy_document
      }
    }
  ]...)

  # Common assume role policies
  ec2_assume_role_policy = jsonencode({
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

  lambda_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  ecs_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}