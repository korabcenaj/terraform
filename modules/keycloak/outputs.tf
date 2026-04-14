output "namespace" {
  description = "Keycloak namespace"
  value       = kubernetes_namespace.keycloak.metadata[0].name
}

output "release_name" {
  description = "Keycloak Helm release name"
  value       = helm_release.keycloak.name
}

output "chart_version" {
  description = "Deployed Keycloak chart version"
  value       = helm_release.keycloak.version
}

output "ingress_host" {
  description = "Keycloak ingress hostname"
  value       = var.ingress_host
}

output "realm" {
  description = "Primary realm intended for local OIDC clients"
  value       = var.realm
}

output "base_url" {
  description = "Base URL for the Keycloak UI"
  value       = "https://${var.ingress_host}"
}

output "issuer_url" {
  description = "Expected issuer URL for the configured realm once the realm exists"
  value       = "https://${var.ingress_host}/realms/${var.realm}"
}
