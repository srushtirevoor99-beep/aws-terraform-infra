output "alb_dns_name" {
  description = "Open this URL in a browser to reach the app"
  value       = module.alb.dns_name
}
