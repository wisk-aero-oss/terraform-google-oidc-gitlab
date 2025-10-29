
output "pool_name" {
  description = "Pool name"
  value       = google_iam_workload_identity_pool.main.name
}

output "provider_name" {
  description = "Provider name"
  value       = google_iam_workload_identity_pool_provider.main.name
}

# Debugging
output "sa_mappings" {
  description = "WIF service account attribute mappings"
  value       = local.sa_mappings
}
output "sa_roles" {
  description = "Roles to bind to ervice accounts"
  value       = local.sa_roles
}
