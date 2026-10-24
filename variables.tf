variable "aws_region" {
  description = "AWS region the infrastructure is created in"
  type        = string
  default     = "ap-south-1"
}

variable "alarm_actions" {
  description = "ARNs notified (for example an SNS topic) when the unhealthy-host alarm changes state"
  type        = list(string)
  default     = []
}
