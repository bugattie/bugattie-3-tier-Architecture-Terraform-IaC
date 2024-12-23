resource "aws_eip" "nat_gateway_eip" {
  count = var.subnet_count

  domain = "vpc"
  tags   = merge(var.tags, lookup(var.tags_for_resource, "aws_eip", {}))
}

resource "aws_nat_gateway" "nat_gateway" {
  count = var.subnet_count

  allocation_id = element(aws_eip.nat_gateway_eip.*.id, count.index)
  subnet_id     = element(var.subnet_ids, count.index)
  tags          = merge(var.tags, lookup(var.tags_for_resource, "aws_nat_gateway", {}))
}