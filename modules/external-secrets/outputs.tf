output "namespace" {
  description = "Namespace where External Secrets Operator is deployed"
  value       = kubernetes_namespace.external_secrets.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.external_secrets.name
}

output "chart_version" {
  description = "Deployed External Secrets chart version"
  value       = helm_release.external_secrets.version
}

output "cluster_secret_store_name" {
  description = "ClusterSecretStore name when enabled"
  value       = var.create_vault_cluster_secret_store ? var.cluster_secret_store_name : null
}