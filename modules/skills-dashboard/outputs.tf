output "service_name" {
  description = "Kubernetes service name for the dashboard"
  value       = kubernetes_service_v1.dashboard.metadata[0].name
}

output "service_port" {
  description = "Service port"
  value       = kubernetes_service_v1.dashboard.spec[0].port[0].port
}

output "namespace" {
  description = "Namespace"
  value       = kubernetes_namespace_v1.dashboard.metadata[0].name
}

output "dashboard_url" {
  description = "Dashboard URL"
  value       = var.enable_ingress ? "http${var.tls_enabled ? "s" : ""}://${var.host}" : "http://${kubernetes_service_v1.dashboard.metadata[0].name}:${kubernetes_service_v1.dashboard.spec[0].port[0].port}"
}
