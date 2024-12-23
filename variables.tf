# Generic variables

variable "aws_region" {
  description = "Region in which you want to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}

# VPC variables

variable "vpc_name" {
  description = "The name for the VPC"
  type        = string
  default     = "MyVPC"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# Public subnet variables

variable "public_cidr_block" {
  description = "The larger CIDR block to use for calculating individual public subnet CIDR blocks"
  type        = string
  default     = "10.0.0.0/23"
}

variable "public_subnet_count" {
  description = "The number of public subnets to create"
  type        = string
  default     = "2"
}

variable "map_public_ip_on_launch" {
  description = "Assign a public IP address to instances launched into the public subnets"
  type        = string
  default     = false
}

# Private subnet variables

variable "application_tier_cidr_block" {
  description = "The larger CIDR block to use for calculating individual private subnet CIDR blocks"
  type        = string
  default     = "10.0.2.0/23"
}

variable "private_subnet_count" {
  description = "The number of private subnets to create"
  type        = string
  default     = "2"
}

variable "database_tier_cidr_block" {
  description = "The larger CIDR block to use for calculating individual private subnet CIDR blocks"
  type        = string
  default     = "10.0.4.0/23"
}

# Web Tier variables

# ALB with Security Group Setup
variable "sg_name" {
  type        = string
  description = "Name of the security group"
  default     = "Web Tier ALB - SG"
}

variable "sg_description" {
  type        = string
  description = "Description of the security group"
  default     = "Security group for Web Tier ALB to allow request from the internet on port 80"
}

# Instance Security Group Setup
variable "instance_sg_name" {
  type        = string
  description = "Name of the security group"
  default     = "Web Tier Instance - SG"
}

variable "instance_sg_description" {
  type        = string
  description = "Description of the security group"
  default     = "Security group for Web Tier Instance to allow request only from the ALB Security Group on port 80"
}

# Application Tier variables
# ALB with Security Group Setup
variable "app_alb_sg_name" {
  type        = string
  description = "Name of the security group"
  default     = "App Tier ALB - SG"
}

variable "app_alb_sg_description" {
  type        = string
  description = "Description of the security group"
  default     = "Security group for App Tier ALB to allow request from the web tier instance on port 80"
}

# Instance Security Group Setup
variable "app_instance_sg_name" {
  type        = string
  description = "Name of the security group"
  default     = "App Tier Instance - SG"
}

variable "app_instance_sg_description" {
  type        = string
  description = "Description of the security group"
  default     = "Security group for App Tier Instance to allow request only from the App Tier ALB Security Group on port 80"
}

# Database Tier variables
# Database Security Group Setup
variable "app_db_sg_name" {
  type        = string
  description = "Name of the database security group"
  default     = "Database Tier - SG"
}

variable "app_db_sg_description" {
  type        = string
  description = "Description of the security group"
  default     = "Security group for DB Tier to allow request from the app tier on port 3306"
}

# Instance Security Group Setup
variable "app_instance_sg_name" {
  type        = string
  description = "Name of the security group"
  default     = "App Tier Instance - SG"
}

variable "app_instance_sg_description" {
  type        = string
  description = "Description of the security group"
  default     = "Security group for App Tier Instance to allow request only from the App Tier ALB Security Group on port 80"
}
