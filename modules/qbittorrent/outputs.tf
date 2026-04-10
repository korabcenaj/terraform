output "namespace" {
  value = var.namespace
}

output "deployment_name" {
  value = kubernetes_deployment.qbittorrent.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.qbittorrent.metadata[0].name
}

output "service_endpoint" {
  value = "${kubernetes_service.qbittorrent.metadata[0].name}.${var.namespace}.svc.cluster.local:8080"
}

output "ingress_host" {
  description = "qBittorrent ingress hostname"
  value       = try(kubernetes_ingress_v1.qbittorrent.spec[0].rule[0].host, null)
}
