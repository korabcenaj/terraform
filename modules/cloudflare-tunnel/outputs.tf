output "namespace" {
  description = "Namespace where cloudflared runs"
  value       = kubernetes_namespace.cloudflare_tunnel.metadata[0].name
}

output "deployment_name" {
  description = "cloudflared deployment name"
  value       = kubernetes_deployment.cloudflared.metadata[0].name
}
