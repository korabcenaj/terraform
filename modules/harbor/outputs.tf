output "namespace" {
  description = "Namespace where Harbor is deployed."
  value       = kubernetes_namespace.harbor.metadata[0].name
}

output "release_name" {
  description = "Helm release name."
  value       = helm_release.harbor.name
}

output "chart_version" {
  description = "Deployed chart version."
  value       = helm_release.harbor.version
}

output "external_url" {
  description = "External URL configured for Harbor."
  value       = var.external_url
}
