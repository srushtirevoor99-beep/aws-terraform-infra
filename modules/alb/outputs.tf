output "dns_name" {
  description = "Public DNS name of the load balancer"
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "ARN of the target group the instances register with"
  value       = aws_lb_target_group.app.arn
}
