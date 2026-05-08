output "namespace" {
  description = "Namespace where Matrix Synapse is deployed"
  value       = kubernetes_namespace.matrix.metadata[0].name
}

output "name" {
  description = "Matrix Synapse deployment/service base name"
  value       = var.name
}

output "ingress_host" {
  description = "Matrix Synapse ingress hostname"
  value       = var.ingress_host
}

output "server_name" {
  description = "Configured Matrix server_name"
  value       = var.server_name
}

output "public_base_url" {
  description = "Configured Matrix public base URL"
  value       = trimspace(var.public_base_url) != "" ? trimspace(var.public_base_url) : "https://${var.ingress_host}"
}

output "oidc_enabled" {
  description = "Whether OIDC login is enabled"
  value       = var.oidc_enabled
}

output "federation_enabled" {
  description = "Whether federation is enabled"
  value       = var.federation_enabled
}
