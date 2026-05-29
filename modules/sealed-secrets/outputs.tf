output "service_account" {
  description = "Sealed Secrets service account name"
  value       = kubernetes_service_account.sealed_secrets.metadata[0].name
}

output "deployment_name" {
  description = "Sealed Secrets deployment name"
  value       = kubernetes_deployment.sealed_secrets.metadata[0].name
}
