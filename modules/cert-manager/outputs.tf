output "namespace" {
  description = "Namespace where cert-manager is deployed"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = try(helm_release.cert_manager[0].name, null)
}

output "chart_version" {
  description = "Deployed cert-manager chart version"
  value       = try(helm_release.cert_manager[0].version, null)
}
