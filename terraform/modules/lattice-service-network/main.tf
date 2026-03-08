resource "aws_vpclattice_service_network" "this" {
  name      = var.name
  auth_type = "NONE"

  tags = var.tags
}

resource "aws_vpclattice_service_network_vpc_association" "this" {
  for_each = { for idx, vpc_id in var.vpc_ids : tostring(idx) => vpc_id }

  service_network_identifier = aws_vpclattice_service_network.this.id
  vpc_identifier             = each.value

  tags = var.tags
}
