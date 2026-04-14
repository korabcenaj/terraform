output "namespace" {
  description = "Namespace where Tempo is deployed"
  value       = kubernetes_namespace.tracing.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.tempo.name
}

output "chart_version" {
  description = "Deployed Tempo chart version"
  value       = helm_release.tempo.version
}

output "service_name" {
  description = "Tempo service name"
  value       = helm_release.tempo.name
}