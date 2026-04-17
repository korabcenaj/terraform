# Sonarr
output "sonarr_namespace" {
  description = "Sonarr namespace"
  value       = try(kubernetes_namespace.app["sonarr"].metadata[0].name, null)
  depends_on  = [module.sonarr]
}

output "sonarr_release" {
  description = "Sonarr Helm release name"
  value       = try(module.sonarr[0].sonarr_name, null)
}

# Radarr
output "radarr_namespace" {
  description = "Radarr namespace"
  value       = try(kubernetes_namespace.app["radarr"].metadata[0].name, null)
  depends_on  = [module.radarr]
}

output "radarr_release" {
  description = "Radarr Helm release name"
  value       = try(module.radarr[0].radarr_name, null)
}
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
  value       = try(kubernetes_namespace.app["portfolio"].metadata[0].name, null)
  depends_on  = [module.portfolio]
}

output "jellyfin_namespace" {
  description = "Jellyfin media server namespace"
  value       = try(kubernetes_namespace.app["jellyfin"].metadata[0].name, null)
  depends_on  = [module.jellyfin]
}

output "qbittorrent_namespace" {
  description = "qBittorrent torrent client namespace"
  value       = try(kubernetes_namespace.app["qbittorrent"].metadata[0].name, null)
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

output "argo_rollouts_namespace" {
  description = "Argo Rollouts namespace"
  value       = try(module.argo_rollouts[0].namespace, null)
}

output "portfolio_rollout_analysis_template" {
  description = "AnalysisTemplate name used for portfolio rollout metric gates"
  value       = try(module.argo_rollout_analysis[0].template_name, null)
}

output "tempo_namespace" {
  description = "Tempo tracing namespace"
  value       = try(module.tempo[0].namespace, null)
}

output "keycloak_namespace" {
  description = "Keycloak namespace"
  value       = try(module.keycloak[0].namespace, null)
}

output "incident_webhook_routing_enabled" {
  description = "Whether Alertmanager incident webhook routing is configured"
  value       = nonsensitive(trimspace(var.alertmanager_incident_webhook_url) != "")
}

output "portfolio_service" {
  description = "Portfolio service information"
  value = try({
    name      = "portfolio-web"
    namespace = kubernetes_namespace.app["portfolio"].metadata[0].name
    type      = "ClusterIP"
    port      = 80
  }, null)
}

output "bootstrapped_namespaces" {
  description = "Namespaces created through the generic namespace bootstrap module"
  value       = { for name, module_instance in module.namespace_bootstrap : name => module_instance.namespace }
}

output "jellyfin_service" {
  description = "Jellyfin service information"
  value = try({
    name      = "jellyfin"
    namespace = kubernetes_namespace.app["jellyfin"].metadata[0].name
    type      = "ClusterIP"
    port      = 8096
  }, null)
}

output "ingress_urls" {
  description = "Primary ingress URLs derived from the configured ingress base domain"
  value = {
    portfolio    = "https://portfolio.${var.ingress_base_domain}"
    jellyfin     = "https://jellyfin.${var.ingress_base_domain}"
    qbittorrent  = "https://qbittorrent.${var.ingress_base_domain}"
    pihole       = "https://pihole.${var.ingress_base_domain}"
    grafana      = "https://grafana.${var.ingress_base_domain}"
    prometheus   = "https://prometheus.${var.ingress_base_domain}"
    minio        = "https://minio.${var.ingress_base_domain}"
    argocd       = "https://argocd.${var.ingress_base_domain}"
    vault        = "https://vault.${var.ingress_base_domain}"
    keycloak     = "https://sso.${var.ingress_base_domain}"
    oauth2_proxy = "https://auth.${var.ingress_base_domain}"
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
    argo_rollouts    = var.enable_argo_rollouts
    tempo            = var.enable_tempo
    keycloak         = var.enable_keycloak
    oauth2_proxy     = var.enable_oauth2_proxy
    kyverno          = var.enable_kyverno
    metrics_server   = var.enable_metrics_server
    slo_alerts       = var.enable_slo_alerts
    gpu_priorities   = var.enable_gpu_priority_classes
    network_policies = var.enable_network_policies
  }
}

output "metrics_server_release" {
  description = "Metrics-server deployment name"
  value       = try(module.metrics_server[0].release_name, null)
}

output "slo_alert_rule_name" {
  description = "PrometheusRule name for portfolio SLO alerts"
  value       = try(module.slo_alerts[0].rule_name, null)
}

output "gpu_priority_classes" {
  description = "GPU PriorityClass names for interactive and batch workloads"
  value = {
    interactive = try(module.gpu_priority_classes[0].interactive_priority_class, null)
    batch       = try(module.gpu_priority_classes[0].batch_priority_class, null)
  }
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

output "argo_rollouts_release" {
  description = "Argo Rollouts Helm release name"
  value       = try(module.argo_rollouts[0].release_name, null)
}

output "tempo_release" {
  description = "Tempo Helm release name"
  value       = try(module.tempo[0].release_name, null)
}

output "keycloak_release" {
  description = "Keycloak Helm release name"
  value       = try(module.keycloak[0].release_name, null)
}

output "keycloak_base_url" {
  description = "Local Keycloak base URL"
  value       = try(module.keycloak[0].base_url, "https://sso.${var.ingress_base_domain}")
}

output "keycloak_issuer_url" {
  description = "Expected OIDC issuer URL for the configured Keycloak realm"
  value       = try(module.keycloak[0].issuer_url, "https://sso.${var.ingress_base_domain}/realms/${var.keycloak_realm}")
}

output "native_oidc_apps" {
  description = "Applications configured to use native OIDC instead of ingress-wide forward-auth"
  value = {
    argocd  = var.enable_argocd_oidc
    grafana = var.enable_grafana_oidc
  }
}

output "oauth2_proxy_namespace" {
  description = "OAuth2 Proxy namespace"
  value       = try(module.oauth2_proxy[0].namespace, null)
}

output "oauth2_proxy_release" {
  description = "OAuth2 Proxy Helm release name"
  value       = try(module.oauth2_proxy[0].release_name, null)
}

output "oauth2_proxy_auth_url" {
  description = "nginx auth-url annotation value for protecting ingresses with OAuth2 Proxy"
  value       = try(module.oauth2_proxy[0].auth_url, "https://auth.${var.ingress_base_domain}/oauth2/auth")
}

output "oauth2_proxy_signin_url" {
  description = "nginx auth-signin annotation value for protected ingresses"
  value       = try(module.oauth2_proxy[0].signin_url, "https://auth.${var.ingress_base_domain}/oauth2/start?rd=$escaped_request_uri")
}

output "kyverno_namespace" {
  description = "Kyverno namespace"
  value       = try(module.kyverno[0].namespace, null)
}

output "kyverno_release" {
  description = "Kyverno Helm release name"
  value       = try(module.kyverno[0].release_name, null)
}

output "kyverno_enforcement_mode" {
  description = "Active Kyverno enforcement mode"
  value       = try(module.kyverno[0].enforcement_mode, null)
}
