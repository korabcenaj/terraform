output "namespace" {
  description = "Namespace where qBittorrent is deployed"
  value       = var.namespace
}

output "service_name" {
  description = "qBittorrent service name"
  value       = kubernetes_service.qbittorrent.metadata[0].name
}

output "ingress_host" {
  description = "qBittorrent Web UI ingress hostname"
  value       = var.ingress_host
}
