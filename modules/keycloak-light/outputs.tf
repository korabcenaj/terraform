output "namespace" {
  description = "Keycloak namespace"
  value       = kubernetes_namespace.keycloak.metadata[0].name
}

output "release_name" {
  description = "Keycloak deployment name"
  value       = kubernetes_deployment_v1.keycloak.metadata[0].name
}

output "ingress_host" {
  description = "Keycloak ingress hostname"
  value       = var.ingress_host
}

output "base_url" {
  description = "Base URL for the Keycloak UI"
  value       = "https://${var.ingress_host}"
}

output "issuer_url" {
  description = "Expected OIDC issuer URL for the default realm"
  value       = "https://${var.ingress_host}/realms/master"
}
