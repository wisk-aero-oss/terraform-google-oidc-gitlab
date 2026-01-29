
output "pool_name" {
  description = "Pool name"
  value       = [for pool in google_iam_workload_identity_pool.main : pool.name]
}

output "provider_name" {
  description = "Provider name"
  value       = [for provider in google_iam_workload_identity_pool_provider.main : provider.name]
}

# Debugging
output "sa_mappings" {
  description = "WIF service account attribute mappings"
  value       = local.sa_mappings
}
output "sa_roles" {
  description = "Roles to bind to service accounts"
  value       = local.sa_roles
}
