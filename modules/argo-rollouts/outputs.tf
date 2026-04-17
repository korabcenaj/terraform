output "namespace" {
  description = "Argo Rollouts namespace"
  value       = kubernetes_namespace.argo_rollouts.metadata[0].name
}

output "release_name" {
  description = "Argo Rollouts Helm release name"
  value       = helm_release.argo_rollouts.name
}

output "chart_version" {
  description = "Deployed Argo Rollouts chart version"
  value       = helm_release.argo_rollouts.version
}

output "dashboard_enabled" {
  description = "Whether the Argo Rollouts dashboard is enabled"
  value       = var.dashboard_enabled
}
