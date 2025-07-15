output "load_balancer_id" {
  description = "ID of the load balancer"
  value       = aws_lb.this.id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.this.arn
}

output "load_balancer_arn_suffix" {
  description = "ARN suffix of the load balancer"
  value       = aws_lb.this.arn_suffix
}

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.this.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID of the load balancer"
  value       = aws_lb.this.zone_id
}

output "load_balancer_type" {
  description = "Type of the load balancer"
  value       = aws_lb.this.load_balancer_type
}

output "security_group_id" {
  description = "ID of the load balancer security group"
  value       = var.load_balancer_type == "application" ? aws_security_group.alb[0].id : null
}

output "target_group_arns" {
  description = "ARNs of the target groups"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "target_group_arn_suffixes" {
  description = "ARN suffixes of the target groups"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn_suffix }
}

output "target_group_names" {
  description = "Names of the target groups"
  value       = { for k, v in aws_lb_target_group.this : k => v.name }
}

output "listener_arns" {
  description = "ARNs of the listeners"
  value       = { for k, v in aws_lb_listener.this : k => v.arn }
}

output "listener_rule_arns" {
  description = "ARNs of the listener rules"
  value       = { for k, v in aws_lb_listener_rule.this : k => v.arn }
}

output "load_balancer_hosted_zone_id" {
  description = "Hosted zone ID for Route53 alias records"
  value       = aws_lb.this.zone_id
}

output "load_balancer_canonical_hosted_zone_id" {
  description = "Canonical hosted zone ID for Route53 alias records (same as zone_id)"
  value       = aws_lb.this.zone_id
}