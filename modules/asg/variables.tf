variable "subnet_ids" {
  description = "Subnets the instances launch into"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ALB target group the instances register with"
  type        = string
}

variable "security_group_id" {
  description = "Security group for the instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (must be free-tier eligible on this account)"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Number of instances the group starts with"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances the CPU scaling policy can launch"
  type        = number
  default     = 4
}
