variable "vpc_id" {
  description = "VPC the target group belongs to"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the load balancer"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group attached to the load balancer"
  type        = string
}

variable "alarm_actions" {
  description = "ARNs notified when the unhealthy-host alarm changes state; empty means the alarm is only visible in the console"
  type        = list(string)
  default     = []
}
