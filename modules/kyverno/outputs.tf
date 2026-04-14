output "namespace" {
  description = "Kyverno namespace"
  value       = kubernetes_namespace.kyverno.metadata[0].name
}

output "release_name" {
  description = "Kyverno Helm release name"
  value       = helm_release.kyverno.name
}

output "chart_version" {
  description = "Deployed chart version"
  value       = helm_release.kyverno.version
}

output "enforcement_mode" {
  description = "Active policy enforcement mode (Audit or Enforce)"
  value       = var.enforcement_mode
}

output "policies_enabled" {
  description = "Whether ClusterPolicy resources have been created"
  value       = var.enable_policies
}
