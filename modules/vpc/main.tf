
// Build a resource for VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags       = merge(var.tags, lookup(var.tags_for_resource, "aws_vpc", {}))
}

// Build a resource for IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(var.tags, lookup(var.tags_for_resource, "aws_internet_gateway", {}))
}