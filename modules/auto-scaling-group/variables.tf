variable "asg_name" {
  type        = string
  description = "Name to assign to Auto Scaling Group"
}

variable "subnet_ids" {
  description = "List of subnet IDS"
  type        = list(string)
}

variable "launch_template_name" {
  type        = string
  description = "Name to assign to Auto Scaling Group"
}

variable "ami_id" {
  type        = string
  description = "AMI Id"
}

variable "security_groups" {
  type        = list(string)
  description = "Security group IDs to assign to instance when created by Launch Templates"
  default     = ["asd"]
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

