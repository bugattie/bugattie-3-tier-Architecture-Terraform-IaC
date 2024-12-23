variable "load_balancer_name" {
  type        = string
  description = "Name for a load balancer"
}

variable "subnet_ids" {
  description = "List of subnet IDs for Load Balancer"
  type        = list(string)
}

variable "alb_security_group_ids" {
  type        = list(string)
  description = "Security group IDs to assign to load balancer"
}

variable "target_group_name" {
  type        = string
  description = "Name for a target group"
}


variable "vpc_id" {
  type        = string
  description = "VPC Id for target group"
}