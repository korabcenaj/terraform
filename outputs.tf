output "cluster_name" {
  description = "Kubernetes cluster name"
  value       = var.cluster_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "portfolio_namespace" {
  description = "Portfolio application namespace"
  value       = try(kubernetes_namespace.portfolio[0].metadata[0].name, null)
  depends_on  = [module.portfolio]
}

output "jellyfin_namespace" {
  description = "Jellyfin media server namespace"
  value       = try(kubernetes_namespace.jellyfin[0].metadata[0].name, null)
  depends_on  = [module.jellyfin]
}

output "qbittorrent_namespace" {
  description = "qBittorrent torrent client namespace"
  value       = try(kubernetes_namespace.qbittorrent[0].metadata[0].name, null)
  depends_on  = [module.qbittorrent]
}


output "portfolio_service" {
  description = "Portfolio service information"
  value = try({
    name      = "portfolio-web"
    namespace = kubernetes_namespace.portfolio[0].metadata[0].name
    type      = "ClusterIP"
    port      = 80
  }, null)
}

output "jellyfin_service" {
  description = "Jellyfin service information"
  value = try({
    name      = "jellyfin"
    namespace = kubernetes_namespace.jellyfin[0].metadata[0].name
    type      = "ClusterIP"
    port      = 8096
  }, null)
}

output "deployed_modules" {
  description = "Deployed modules summary"
  value = {
    portfolio        = var.enable_portfolio
    jellyfin         = var.enable_jellyfin
    qbittorrent      = var.enable_qbittorrent
    pihole           = var.enable_pihole
    monitoring       = var.enable_monitoring
    metrics_server   = var.enable_metrics_server
    network_policies = var.enable_network_policies
  }
}

output "metrics_server_release" {
  description = "Metrics-server deployment name"
  value       = try(module.metrics_server[0].release_name, null)
}
