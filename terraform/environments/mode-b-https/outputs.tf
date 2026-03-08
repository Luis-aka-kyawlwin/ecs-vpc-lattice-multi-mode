output "mode" {
  value = "mode-b-https"
}

output "counting_service_dns" {
  value = module.lattice_service.service_dns_name
}

output "lattice_target_group_arn" {
  value = module.lattice_service.target_group_arn
}

output "dashboard_cluster_name" {
  value = module.cluster_dashboard.cluster_name
}

output "counting_cluster_name" {
  value = module.cluster_counting.cluster_name
}

output "dashboard_service_name" {
  value = module.dashboard_service.service_name
}

output "counting_service_name" {
  value = module.counting_service.service_name
}

output "public_alb_dns_name" {
  value = var.enable_public_alb ? aws_lb.dashboard[0].dns_name : null
}

output "public_dashboard_url" {
  value = var.enable_public_alb ? "https://${aws_lb.dashboard[0].dns_name}" : null
}
