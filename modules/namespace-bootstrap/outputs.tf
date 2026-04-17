output "namespace" {
  description = "Bootstrapped namespace name"
  value       = kubernetes_namespace.this.metadata[0].name
}

output "resource_quota_name" {
  description = "ResourceQuota name"
  value       = kubernetes_resource_quota.this.metadata[0].name
}

output "limit_range_name" {
  description = "LimitRange name"
  value       = kubernetes_limit_range.this.metadata[0].name
}
