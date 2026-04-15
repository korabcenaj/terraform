################################################################################
# Docker-Apps Kubernetes Infrastructure as Code
# Manages all cluster and application deployments
################################################################################

locals {
  portfolio_host    = "portfolio.${var.ingress_base_domain}"
  jellyfin_host     = "jellyfin.${var.ingress_base_domain}"
  qbittorrent_host  = "qbittorrent.${var.ingress_base_domain}"
  pihole_host       = "pihole.${var.ingress_base_domain}"
  grafana_host      = "grafana.${var.ingress_base_domain}"
  prometheus_host   = "prometheus.${var.ingress_base_domain}"
  minio_host        = "minio.${var.ingress_base_domain}"
  argocd_host       = "argocd.${var.ingress_base_domain}"
  vault_host        = "vault.${var.ingress_base_domain}"
  keycloak_host     = "sso.${var.ingress_base_domain}"
  keycloak_issuer   = "https://sso.${var.ingress_base_domain}/realms/${var.keycloak_realm}"
  oauth2_proxy_host = "auth.${var.ingress_base_domain}"
  # Prefer explicit override, otherwise use the Pi-hole Service ClusterIP directly
  # so CoreDNS does not need to resolve its own upstream target.
  private_dns_upstream = trimspace(var.private_dns_ip) != "" ? trimspace(var.private_dns_ip) : (
    var.enable_pihole ? try(module.pihole[0].cluster_ip, "") : ""
  )
}

# ---------------------------------------------------------------------------
# Infrastructure: cert-manager, ingress-nginx, kube-prometheus-stack
# ---------------------------------------------------------------------------

module "cert_manager" {
  count  = var.enable_cert_manager ? 1 : 0
  source = "./modules/cert-manager"

  release_name             = "cert-manager"
  chart_version            = var.cert_manager_chart_version
  manage_controller_install = var.manage_cert_manager_controller
  create_selfsigned_issuer = true
  create_local_ca_issuer   = true

  tags = var.tags
}

data "kubernetes_secret_v1" "local_lan_ca" {
  count = var.enable_argocd && var.enable_argocd_oidc && var.enable_cert_manager ? 1 : 0

  metadata {
    name      = "local-lan-ca-secret"
    namespace = "cert-manager"
  }

  depends_on = [module.cert_manager]
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

  release_name               = "monitor"
  chart_version              = var.kube_prometheus_stack_chart_version
  grafana_admin_password     = var.grafana_admin_password
  prometheus_retention       = var.prometheus_retention
  prometheus_storage_size    = var.prometheus_storage_size
  prometheus_storage_class   = var.prometheus_storage_class
  grafana_storage_size       = var.grafana_storage_size
  grafana_storage_class      = var.grafana_storage_class
  grafana_host               = local.grafana_host
  grafana_oidc_enabled       = var.enable_grafana_oidc
  grafana_oidc_name          = "Keycloak"
  grafana_oidc_issuer_url    = local.keycloak_issuer
  grafana_oidc_client_id     = var.grafana_oidc_client_id
  grafana_oidc_client_secret = var.grafana_oidc_client_secret

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
  ingress_host  = local.minio_host

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
  ingress_host  = local.vault_host

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
  oidc_enabled          = var.enable_argocd_oidc
  oidc_name             = "Keycloak"
  oidc_issuer_url       = local.keycloak_issuer
  oidc_client_id        = var.argocd_oidc_client_id
  oidc_client_secret    = var.argocd_oidc_client_secret
  oidc_root_ca_pem      = try(data.kubernetes_secret_v1.local_lan_ca[0].data["tls.crt"], "")
  ingress_host          = local.argocd_host

  tags = var.tags

  depends_on = [module.cert_manager]
}

module "keycloak" {
  count  = var.enable_keycloak ? 1 : 0
  source = "./modules/keycloak"

  release_name             = "keycloak"
  chart_version            = var.keycloak_chart_version
  admin_user               = var.keycloak_admin_user
  admin_password           = var.keycloak_admin_password
  postgresql_username      = var.keycloak_postgresql_username
  postgresql_password      = var.keycloak_postgresql_password
  postgresql_database      = var.keycloak_postgresql_database
  postgresql_storage_class = var.keycloak_postgresql_storage_class
  postgresql_storage_size  = var.keycloak_postgresql_storage_size
  ingress_host             = local.keycloak_host
  realm                    = var.keycloak_realm
  bootstrap_enabled        = var.keycloak_bootstrap_enabled
  argocd_client_id         = var.argocd_oidc_client_id
  argocd_client_secret     = var.argocd_oidc_client_secret
  argocd_redirect_uris     = ["https://${local.argocd_host}/auth/callback"]
  argocd_web_origins       = ["https://${local.argocd_host}"]
  grafana_client_id        = var.grafana_oidc_client_id
  grafana_client_secret    = var.grafana_oidc_client_secret
  grafana_redirect_uris    = ["https://${local.grafana_host}/login/generic_oauth"]
  grafana_web_origins      = ["https://${local.grafana_host}"]

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

module "oauth2_proxy" {
  count  = var.enable_oauth2_proxy ? 1 : 0
  source = "./modules/oauth2-proxy"

  release_name    = "oauth2-proxy"
  chart_version   = var.oauth2_proxy_chart_version
  oauth2_provider = var.oauth2_proxy_provider
  email_domain    = var.oauth2_proxy_email_domain
  client_id       = var.oauth2_proxy_client_id
  client_secret   = var.oauth2_proxy_client_secret
  cookie_secret   = var.oauth2_proxy_cookie_secret
  ingress_host    = local.oauth2_proxy_host

  tags = var.tags
}

module "kyverno" {
  count  = var.enable_kyverno ? 1 : 0
  source = "./modules/kyverno"

  release_name     = "kyverno"
  chart_version    = var.kyverno_chart_version
  enforcement_mode = var.kyverno_enforcement_mode
  enable_policies  = var.kyverno_create_policies

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

module "gpu_device_plugins" {
  count  = var.enable_gpu_device_plugins ? 1 : 0
  source = "./modules/gpu-device-plugins"

  namespace                = "kube-system"
  enable_intel_gpu_plugin  = var.enable_intel_gpu_plugin
  enable_amd_gpu_plugin    = var.enable_amd_gpu_plugin
  enable_nvidia_gpu_plugin = var.enable_nvidia_gpu_plugin
  intel_gpu_plugin_image   = var.intel_gpu_plugin_image
  amd_gpu_plugin_image     = var.amd_gpu_plugin_image
  nvidia_gpu_plugin_image  = var.nvidia_gpu_plugin_image
  nvidia_node_selector     = var.nvidia_node_selector

  tags = var.tags
}

module "networking" {
  count  = var.enable_network_policies ? 1 : 0
  source = "./modules/networking"

  coredns_local_domain = var.ingress_base_domain
  coredns_local_dns_ip = local.private_dns_upstream

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
