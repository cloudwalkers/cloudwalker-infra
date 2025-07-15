output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "service_id" {
  description = "ID of the ECS service"
  value       = var.create_service ? aws_ecs_service.this[0].id : null
}

output "service_name" {
  description = "Name of the ECS service"
  value       = var.create_service ? aws_ecs_service.this[0].name : null
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = var.create_service ? aws_ecs_task_definition.this[0].arn : null
}

output "security_group_id" {
  description = "ID of the ECS service security group"
  value       = var.create_service ? aws_security_group.ecs_service[0].id : null
}

# IAM Outputs
output "execution_role_arn" {
  description = "ARN of the ECS execution role"
  value       = var.create_iam_roles ? aws_iam_role.ecs_execution[0].arn : var.execution_role_arn
}

output "execution_role_name" {
  description = "Name of the ECS execution role"
  value       = var.create_iam_roles ? aws_iam_role.ecs_execution[0].name : null
}

output "task_role_arn" {
  description = "ARN of the ECS task role"
  value       = var.create_iam_roles ? aws_iam_role.ecs_task[0].arn : var.task_role_arn
}

output "task_role_name" {
  description = "Name of the ECS task role"
  value       = var.create_iam_roles ? aws_iam_role.ecs_task[0].name : null
}