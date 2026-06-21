output "namespace" {
  description = "Namespace where Loki is deployed"
  value       = kubernetes_namespace.logging.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.loki.name
}

output "chart_version" {
  description = "Deployed Loki chart version"
  value       = helm_release.loki.version
}

output "loki_service_name" {
  description = "Service name for Loki"
  value       = helm_release.loki.name
}