output "namespace" {
  description = "Namespace where Vault is deployed"
  value       = kubernetes_namespace.vault.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.vault.name
}

output "chart_version" {
  description = "Deployed Vault chart version"
  value       = helm_release.vault.version
}

output "service_name" {
  description = "Vault service name"
  value       = helm_release.vault.name
}