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

output "loki_namespace" {
  description = "Loki logging namespace"
  value       = try(module.loki[0].namespace, null)
}

output "minio_namespace" {
  description = "MinIO storage namespace"
  value       = try(module.minio[0].namespace, null)
}

output "velero_namespace" {
  description = "Velero backup namespace"
  value       = try(module.velero[0].namespace, null)
}

output "vault_namespace" {
  description = "Vault namespace"
  value       = try(module.vault[0].namespace, null)
}

output "external_secrets_namespace" {
  description = "External Secrets namespace"
  value       = try(module.external_secrets[0].namespace, null)
}

output "argocd_namespace" {
  description = "Argo CD namespace"
  value       = try(module.argocd[0].namespace, null)
}

output "tempo_namespace" {
  description = "Tempo tracing namespace"
  value       = try(module.tempo[0].namespace, null)
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

output "ingress_urls" {
  description = "Primary ingress URLs derived from the configured ingress base domain"
  value = {
    portfolio   = "https://portfolio.${var.ingress_base_domain}"
    jellyfin    = "https://jellyfin.${var.ingress_base_domain}"
    qbittorrent = "https://qbittorrent.${var.ingress_base_domain}"
    pihole      = "https://pihole.${var.ingress_base_domain}"
    grafana     = "https://grafana.${var.ingress_base_domain}"
    prometheus  = "https://prometheus.${var.ingress_base_domain}"
  }
}

output "deployed_modules" {
  description = "Deployed modules summary"
  value = {
    portfolio        = var.enable_portfolio
    jellyfin         = var.enable_jellyfin
    qbittorrent      = var.enable_qbittorrent
    pihole           = var.enable_pihole
    monitoring       = var.enable_monitoring
    loki             = var.enable_loki
    minio            = var.enable_minio
    velero           = var.enable_velero
    vault            = var.enable_vault
    external_secrets = var.enable_external_secrets
    argocd           = var.enable_argocd
    tempo            = var.enable_tempo
    metrics_server   = var.enable_metrics_server
    network_policies = var.enable_network_policies
  }
}

output "metrics_server_release" {
  description = "Metrics-server deployment name"
  value       = try(module.metrics_server[0].release_name, null)
}

output "loki_release" {
  description = "Loki Helm release name"
  value       = try(module.loki[0].release_name, null)
}

output "minio_release" {
  description = "MinIO Helm release name"
  value       = try(module.minio[0].release_name, null)
}

output "velero_release" {
  description = "Velero Helm release name"
  value       = try(module.velero[0].release_name, null)
}

output "vault_release" {
  description = "Vault Helm release name"
  value       = try(module.vault[0].release_name, null)
}

output "external_secrets_release" {
  description = "External Secrets Helm release name"
  value       = try(module.external_secrets[0].release_name, null)
}

output "argocd_release" {
  description = "Argo CD Helm release name"
  value       = try(module.argocd[0].release_name, null)
}

output "tempo_release" {
  description = "Tempo Helm release name"
  value       = try(module.tempo[0].release_name, null)
}
