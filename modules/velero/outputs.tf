output "namespace" {
  description = "Namespace where Velero is deployed"
  value       = kubernetes_namespace.velero.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.velero.name
}

output "chart_version" {
  description = "Deployed Velero chart version"
  value       = helm_release.velero.version
}