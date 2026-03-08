output "mode" {
  value = "mode-a-http"
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
