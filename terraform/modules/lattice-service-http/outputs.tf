output "service_id" {
  value = aws_vpclattice_service.this.id
}

output "target_group_arn" {
  value = aws_vpclattice_target_group.this.arn
}

output "service_dns_name" {
  value = aws_vpclattice_service.this.dns_entry[0].domain_name
}
