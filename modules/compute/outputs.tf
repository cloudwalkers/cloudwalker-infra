// outputs.tf
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.this.name
}

output "route53_record" {
  value = aws_route53_record.this.name
}