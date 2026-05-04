output "namespace" {
  description = "Namespace where n8n is deployed"
  value       = kubernetes_namespace.n8n.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.n8n.name
}

output "chart_version" {
  description = "Deployed n8n chart version"
  value       = helm_release.n8n.version
}

output "ingress_host" {
  description = "n8n ingress hostname"
  value       = var.ingress_host
}

output "webhook_url" {
  description = "Webhook base URL configured for n8n"
  value       = local.webhook_url
}
