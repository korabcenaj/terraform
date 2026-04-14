################################################################################
# Docker-Apps Kubernetes Infrastructure as Code
# Manages all cluster and application deployments
################################################################################

locals {
  portfolio_host   = "portfolio.${var.ingress_base_domain}"
  jellyfin_host    = "jellyfin.${var.ingress_base_domain}"
  qbittorrent_host = "qbittorrent.${var.ingress_base_domain}"
  pihole_host      = "pihole.${var.ingress_base_domain}"
  grafana_host     = "grafana.${var.ingress_base_domain}"
  prometheus_host  = "prometheus.${var.ingress_base_domain}"
}

# ---------------------------------------------------------------------------
# Infrastructure: cert-manager, ingress-nginx, kube-prometheus-stack
# ---------------------------------------------------------------------------

module "cert_manager" {
  count  = var.enable_cert_manager ? 1 : 0
  source = "./modules/cert-manager"

  release_name             = "cert-manager"
  chart_version            = var.cert_manager_chart_version
  create_selfsigned_issuer = true
  create_local_ca_issuer   = true

  tags = var.tags
}

module "ingress_nginx" {
  count  = var.enable_ingress_nginx ? 1 : 0
  source = "./modules/ingress-nginx"

  release_name   = "ingress-nginx"
  chart_version  = var.ingress_nginx_chart_version
  service_type   = var.ingress_nginx_service_type
  replica_count  = var.ingress_nginx_replicas
  enable_metrics = var.enable_monitoring

  tags = var.tags
}

module "kube_prometheus_stack" {
  count  = var.enable_kube_prometheus_stack ? 1 : 0
  source = "./modules/kube-prometheus-stack"

  release_name             = "monitor"
  chart_version            = var.kube_prometheus_stack_chart_version
  grafana_admin_password   = var.grafana_admin_password
  prometheus_retention     = var.prometheus_retention
  prometheus_storage_size  = var.prometheus_storage_size
  prometheus_storage_class = var.prometheus_storage_class
  grafana_storage_size     = var.grafana_storage_size
  grafana_storage_class    = var.grafana_storage_class

  tags = var.tags
}

module "loki" {
  count  = var.enable_loki ? 1 : 0
  source = "./modules/loki"

  release_name       = "loki"
  chart_version      = var.loki_chart_version
  loki_storage_size  = var.loki_storage_size
  loki_storage_class = var.loki_storage_class

  tags = var.tags
}

module "minio" {
  count  = var.enable_minio ? 1 : 0
  source = "./modules/minio"

  release_name  = "minio"
  chart_version = var.minio_chart_version
  root_user     = var.minio_root_user
  root_password = var.minio_root_password
  storage_size  = var.minio_storage_size
  storage_class = var.minio_storage_class

  tags = var.tags
}

module "velero" {
  count  = var.enable_velero ? 1 : 0
  source = "./modules/velero"

  release_name  = "velero"
  chart_version = var.velero_chart_version
  bucket_name   = var.velero_bucket_name
  s3_url        = var.velero_s3_url
  access_key    = var.minio_root_user
  secret_key    = var.minio_root_password

  tags = var.tags

  depends_on = [module.minio]
}

module "vault" {
  count  = var.enable_vault ? 1 : 0
  source = "./modules/vault"

  release_name  = "vault"
  chart_version = var.vault_chart_version
  storage_size  = var.vault_storage_size
  storage_class = var.vault_storage_class

  tags = var.tags
}

module "external_secrets" {
  count  = var.enable_external_secrets ? 1 : 0
  source = "./modules/external-secrets"

  release_name                      = "external-secrets"
  chart_version                     = var.external_secrets_chart_version
  create_vault_cluster_secret_store = var.create_vault_cluster_secret_store
  cluster_secret_store_name         = var.external_secrets_cluster_secret_store_name
  vault_server                      = var.external_secrets_vault_server
  vault_kv_path                     = var.external_secrets_vault_kv_path
  vault_token                       = var.vault_token

  tags = var.tags

  depends_on = [module.vault]
}

module "argocd" {
  count  = var.enable_argocd ? 1 : 0
  source = "./modules/argocd"

  release_name          = "argocd"
  chart_version         = var.argocd_chart_version
  admin_password_bcrypt = var.argocd_admin_password_bcrypt

  tags = var.tags
}

module "tempo" {
  count  = var.enable_tempo ? 1 : 0
  source = "./modules/tempo"

  release_name  = "tempo"
  chart_version = var.tempo_chart_version
  storage_size  = var.tempo_storage_size
  storage_class = var.tempo_storage_class

  tags = var.tags
}

# Namespaces
resource "kubernetes_namespace" "portfolio" {
  count = var.enable_portfolio ? 1 : 0

  metadata {
    name = "portfolio"
    labels = {
      name                                 = "portfolio"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_namespace" "jellyfin" {
  count = var.enable_jellyfin ? 1 : 0

  metadata {
    name = "jellyfin"
    labels = {
      name                                 = "jellyfin"
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_namespace" "qbittorrent" {
  count = var.enable_qbittorrent ? 1 : 0

  metadata {
    name = "qbittorrent"
    labels = {
      name                                 = "qbittorrent"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    }
  }
}

resource "kubernetes_namespace" "pihole" {
  count = var.enable_pihole ? 1 : 0

  metadata {
    name = "pihole"
    labels = {
      name                                 = "pihole"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

# Modules
module "portfolio" {
  count  = var.enable_portfolio && var.manage_portfolio_workload ? 1 : 0
  source = "./modules/portfolio"

  namespace      = kubernetes_namespace.portfolio[0].metadata[0].name
  replicas       = var.portfolio_replicas
  cpu_request    = var.default_cpu_request
  memory_request = var.default_memory_request
  cpu_limit      = var.default_cpu_limit
  memory_limit   = var.default_memory_limit
  ingress_host   = local.portfolio_host

  tags = var.tags
}

module "jellyfin" {
  count  = var.enable_jellyfin ? 1 : 0
  source = "./modules/jellyfin"

  namespace      = kubernetes_namespace.jellyfin[0].metadata[0].name
  replicas       = var.jellyfin_replicas
  storage_class  = var.jellyfin_storage_class
  config_size    = var.jellyfin_config_size
  cache_size     = var.jellyfin_cache_size
  node_name      = var.jellyfin_node_name
  media_path     = var.jellyfin_media_path
  cpu_request    = "250m"
  memory_request = "512Mi"
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  ingress_host   = local.jellyfin_host

  tags = var.tags
}

module "qbittorrent" {
  count  = var.enable_qbittorrent ? 1 : 0
  source = "./modules/qbittorrent"

  namespace      = kubernetes_namespace.qbittorrent[0].metadata[0].name
  replicas       = var.qbittorrent_replicas
  cpu_request    = "250m"
  memory_request = "256Mi"
  cpu_limit      = "500m"
  memory_limit   = "1Gi"
  ingress_host   = local.qbittorrent_host

  tags = var.tags
}

module "pihole" {
  count  = var.enable_pihole ? 1 : 0
  source = "./modules/pihole"

  namespace           = kubernetes_namespace.pihole[0].metadata[0].name
  replicas            = 1
  web_password        = var.pihole_web_password
  timezone            = "UTC"
  cpu_request         = "100m"
  memory_request      = "128Mi"
  cpu_limit           = "250m"
  memory_limit        = "512Mi"
  ingress_host        = local.pihole_host
  dns_wildcard_domain = var.ingress_base_domain

  tags = var.tags
}

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  grafana_service_name    = var.enable_kube_prometheus_stack ? try(module.kube_prometheus_stack[0].grafana_service_name, "monitor-grafana") : "monitor-grafana"
  prometheus_service_name = var.enable_kube_prometheus_stack ? try(module.kube_prometheus_stack[0].prometheus_service_name, "monitor-kube-prometheus-st-prometheus") : "monitor-kube-prometheus-st-prometheus"
  grafana_host            = local.grafana_host
  prometheus_host         = local.prometheus_host

  tags = var.tags

  depends_on = [module.kube_prometheus_stack]
}

module "metrics_server" {
  count  = var.enable_metrics_server ? 1 : 0
  source = "./modules/metrics-server"
}

module "networking" {
  count  = var.enable_network_policies ? 1 : 0
  source = "./modules/networking"

  namespaces_with_policies = compact([
    "default",
    var.enable_portfolio ? "portfolio" : "",
    var.enable_jellyfin ? "jellyfin" : "",
    var.enable_qbittorrent ? "qbittorrent" : "",
    var.enable_pihole ? "pihole" : "",
    var.enable_loki ? "logging" : "",
    var.enable_minio ? "minio" : "",
    var.enable_velero ? "velero" : "",
    var.enable_vault ? "vault" : "",
    var.enable_external_secrets ? "external-secrets" : "",
    var.enable_argocd ? "argocd" : "",
    var.enable_tempo ? "tracing" : "",
    # monitoring has its own namespace-specific policies in the monitoring module
    # ingress-nginx should not receive a blanket default-deny without explicit allow rules
    var.enable_cert_manager ? "cert-manager" : "",
  ])
}

# Resource Quotas
module "resource_quotas" {
  count  = var.enable_resource_quotas ? 1 : 0
  source = "./modules/resource-quotas"

  enable_portfolio_quota   = var.enable_portfolio
  enable_qbittorrent_quota = var.enable_qbittorrent
  enable_jellyfin_quota    = var.enable_jellyfin
  enable_pihole_quota      = var.enable_pihole

  portfolio_namespace   = try(kubernetes_namespace.portfolio[0].metadata[0].name, "portfolio")
  qbittorrent_namespace = try(kubernetes_namespace.qbittorrent[0].metadata[0].name, "qbittorrent")
  jellyfin_namespace    = try(kubernetes_namespace.jellyfin[0].metadata[0].name, "jellyfin")
  pihole_namespace      = try(kubernetes_namespace.pihole[0].metadata[0].name, "pihole")

  tags = var.tags
}

# Network Policies
module "network_policies" {
  count  = var.enable_network_policies ? 1 : 0
  source = "./modules/network-policies"

  enable_portfolio_netpol   = var.enable_portfolio
  enable_qbittorrent_netpol = var.enable_qbittorrent
  enable_jellyfin_netpol    = var.enable_jellyfin
  enable_pihole_netpol      = var.enable_pihole

  portfolio_namespace   = try(kubernetes_namespace.portfolio[0].metadata[0].name, "portfolio")
  qbittorrent_namespace = try(kubernetes_namespace.qbittorrent[0].metadata[0].name, "qbittorrent")
  jellyfin_namespace    = try(kubernetes_namespace.jellyfin[0].metadata[0].name, "jellyfin")
  pihole_namespace      = try(kubernetes_namespace.pihole[0].metadata[0].name, "pihole")

  tags = var.tags
}

# Pod Disruption Budgets
module "pod_disruption_budgets" {
  count  = var.enable_pod_disruption_budgets ? 1 : 0
  source = "./modules/pod-disruption-budgets"

  enable_portfolio_pdb   = var.enable_portfolio
  enable_qbittorrent_pdb = var.enable_qbittorrent
  enable_jellyfin_pdb    = var.enable_jellyfin
  enable_pihole_pdb      = var.enable_pihole

  portfolio_namespace   = try(kubernetes_namespace.portfolio[0].metadata[0].name, "portfolio")
  qbittorrent_namespace = try(kubernetes_namespace.qbittorrent[0].metadata[0].name, "qbittorrent")
  jellyfin_namespace    = try(kubernetes_namespace.jellyfin[0].metadata[0].name, "jellyfin")
  pihole_namespace      = try(kubernetes_namespace.pihole[0].metadata[0].name, "pihole")

  tags = var.tags
}
