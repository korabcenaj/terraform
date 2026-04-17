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

  app_namespace_config = {
    portfolio = {
      enabled                   = var.enable_portfolio
      pod_security_enforce      = "baseline"
      include_restricted_labels = true
    }
    jellyfin = {
      enabled                   = var.enable_jellyfin
      pod_security_enforce      = "privileged"
      include_restricted_labels = true
    }
    qbittorrent = {
      enabled                   = var.enable_qbittorrent
      pod_security_enforce      = "baseline"
      include_restricted_labels = true
    }
    pihole = {
      enabled                   = var.enable_pihole
      pod_security_enforce      = "privileged"
      include_restricted_labels = false
    }
  }
  sonarr = {
    enabled                   = var.enable_sonarr
    pod_security_enforce      = "baseline"
    include_restricted_labels = true
  }
  radarr = {
    enabled                   = var.enable_radarr
    pod_security_enforce      = "baseline"
    include_restricted_labels = true
  }
}

# ---------------------------------------------------------------------------
# Infrastructure: cert-manager, ingress-nginx, kube-prometheus-stack
# ---------------------------------------------------------------------------

module "cert_manager" {
  count  = var.enable_cert_manager ? 1 : 0
  source = "./modules/cert-manager"

  release_name              = "cert-manager"
  chart_version             = var.cert_manager_chart_version
  manage_controller_install = var.manage_cert_manager_controller
  create_selfsigned_issuer  = true
  create_local_ca_issuer    = true

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

  release_name       = "ingress-nginx"
  chart_version      = var.ingress_nginx_chart_version
  service_type       = var.ingress_nginx_service_type
  replica_count      = var.ingress_nginx_replicas
  enable_metrics     = var.enable_monitoring
  limit_rps          = var.ingress_nginx_limit_rps
  limit_connections  = var.ingress_nginx_limit_connections
  enable_modsecurity = var.ingress_nginx_enable_modsecurity
  enable_owasp_crs   = var.ingress_nginx_enable_owasp_crs

  tags = var.tags
}

module "kube_prometheus_stack" {
  count  = var.enable_kube_prometheus_stack ? 1 : 0
  source = "./modules/kube-prometheus-stack"

  release_name                           = "monitor"
  chart_version                          = var.kube_prometheus_stack_chart_version
  grafana_admin_password                 = var.grafana_admin_password
  prometheus_retention                   = var.prometheus_retention
  prometheus_storage_size                = var.prometheus_storage_size
  prometheus_storage_class               = var.prometheus_storage_class
  grafana_storage_size                   = var.grafana_storage_size
  grafana_storage_class                  = var.grafana_storage_class
  grafana_host                           = local.grafana_host
  grafana_oidc_enabled                   = var.enable_grafana_oidc
  grafana_oidc_name                      = "Keycloak"
  grafana_oidc_issuer_url                = local.keycloak_issuer
  grafana_oidc_client_id                 = var.grafana_oidc_client_id
  grafana_oidc_client_secret             = var.grafana_oidc_client_secret
  alertmanager_incident_webhook_url      = var.alertmanager_incident_webhook_url
  alertmanager_incident_minimum_severity = var.alertmanager_incident_minimum_severity
  alertmanager_incident_send_resolved    = var.alertmanager_incident_send_resolved

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

module "argo_rollouts" {
  count  = var.enable_argo_rollouts ? 1 : 0
  source = "./modules/argo-rollouts"

  release_name      = "argo-rollouts"
  chart_version     = var.argo_rollouts_chart_version
  dashboard_enabled = var.argo_rollouts_dashboard_enabled

  tags = var.tags
}

module "argo_rollout_analysis" {
  count  = var.enable_argo_rollouts && var.enable_portfolio_rollout_metric_gates && var.enable_portfolio ? 1 : 0
  source = "./modules/argo-rollout-analysis"

  namespace                     = kubernetes_namespace.app["portfolio"].metadata[0].name
  template_name                 = "portfolio-rollout-metrics"
  portfolio_host                = local.portfolio_host
  prometheus_address            = var.portfolio_rollout_metrics_prometheus_address
  success_rate_minimum_percent  = var.portfolio_rollout_success_rate_minimum_percent
  latency_p95_threshold_seconds = var.portfolio_rollout_latency_p95_threshold_seconds

  tags = var.tags

  depends_on = [module.argo_rollouts, module.kube_prometheus_stack]
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
moved {
  from = kubernetes_namespace.portfolio[0]
  to   = kubernetes_namespace.app["portfolio"]
}

moved {
  from = kubernetes_namespace.jellyfin[0]
  to   = kubernetes_namespace.app["jellyfin"]
}

moved {
  from = kubernetes_namespace.qbittorrent[0]
  to   = kubernetes_namespace.app["qbittorrent"]
}

moved {
  from = kubernetes_namespace.pihole[0]
  to   = kubernetes_namespace.app["pihole"]
}

resource "kubernetes_namespace" "app" {
  for_each = { for name, cfg in local.app_namespace_config : name => cfg if cfg.enabled }

  metadata {
    name = each.key
    labels = merge({
      name                                 = each.key
      "pod-security.kubernetes.io/enforce" = each.value.pod_security_enforce
      }, each.value.include_restricted_labels ? {
      "pod-security.kubernetes.io/audit" = "restricted"
      "pod-security.kubernetes.io/warn"  = "restricted"
    } : {})
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# Modules
module "portfolio" {
  count  = var.enable_portfolio && var.manage_portfolio_workload ? 1 : 0
  source = "./modules/portfolio"

  namespace      = kubernetes_namespace.app["portfolio"].metadata[0].name
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

  namespace      = kubernetes_namespace.app["jellyfin"].metadata[0].name
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

  namespace      = kubernetes_namespace.app["qbittorrent"].metadata[0].name
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

  namespace           = kubernetes_namespace.app["pihole"].metadata[0].name
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

# Sonarr
module "sonarr" {
  count                        = var.enable_sonarr ? 1 : 0
  source                       = "./modules/sonarr"
  namespace                    = kubernetes_namespace.app["sonarr"].metadata[0].name
  chart_version                = var.sonarr_chart_version
  jellyfin_service_endpoint    = try(module.jellyfin[0].service_endpoint, "")
  qbittorrent_service_endpoint = try(module.qbittorrent[0].service_endpoint, "")
  # Optionally add persistence, env, ingress, resources as needed
  tags = var.tags
}

# Radarr
module "radarr" {
  count                        = var.enable_radarr ? 1 : 0
  source                       = "./modules/radarr"
  namespace                    = kubernetes_namespace.app["radarr"].metadata[0].name
  chart_version                = var.radarr_chart_version
  jellyfin_service_endpoint    = try(module.jellyfin[0].service_endpoint, "")
  qbittorrent_service_endpoint = try(module.qbittorrent[0].service_endpoint, "")
  # Optionally add persistence, env, ingress, resources as needed
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

module "gpu_priority_classes" {
  count  = var.enable_gpu_priority_classes ? 1 : 0
  source = "./modules/gpu-priority-classes"

  interactive_priority_name  = var.gpu_interactive_priority_name
  interactive_priority_value = var.gpu_interactive_priority_value
  batch_priority_name        = var.gpu_batch_priority_name
  batch_priority_value       = var.gpu_batch_priority_value

  tags = var.tags
}

module "namespace_bootstrap" {
  for_each = var.bootstrap_namespaces
  source   = "./modules/namespace-bootstrap"

  name                   = each.key
  pod_security_enforce   = try(each.value.pod_security_enforce, "baseline")
  pod_security_audit     = try(each.value.pod_security_audit, "restricted")
  pod_security_warn      = try(each.value.pod_security_warn, "restricted")
  pod_limit              = try(each.value.pod_limit, "10")
  cpu_request_quota      = try(each.value.cpu_request_quota, "500m")
  memory_request_quota   = try(each.value.memory_request_quota, "512Mi")
  cpu_limit_quota        = try(each.value.cpu_limit_quota, "1000m")
  memory_limit_quota     = try(each.value.memory_limit_quota, "1Gi")
  default_cpu_request    = try(each.value.default_cpu_request, var.default_cpu_request)
  default_memory_request = try(each.value.default_memory_request, var.default_memory_request)
  default_cpu_limit      = try(each.value.default_cpu_limit, var.default_cpu_limit)
  default_memory_limit   = try(each.value.default_memory_limit, var.default_memory_limit)
  create_default_deny    = try(each.value.create_default_deny, true)

  tags = var.tags
}

module "slo_alerts" {
  count  = var.enable_slo_alerts ? 1 : 0
  source = "./modules/slo-alerts"

  namespace                   = "monitoring"
  rule_name                   = "portfolio-slo-alerts"
  portfolio_host              = local.portfolio_host
  availability_target_percent = var.slo_portfolio_availability_target_percent
  latency_p95_seconds         = var.slo_portfolio_latency_p95_seconds
  prometheus_release_label    = var.slo_prometheus_release_label

  tags = var.tags

  depends_on = [module.kube_prometheus_stack]
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

  portfolio_namespace   = try(kubernetes_namespace.app["portfolio"].metadata[0].name, "portfolio")
  qbittorrent_namespace = try(kubernetes_namespace.app["qbittorrent"].metadata[0].name, "qbittorrent")
  jellyfin_namespace    = try(kubernetes_namespace.app["jellyfin"].metadata[0].name, "jellyfin")
  pihole_namespace      = try(kubernetes_namespace.app["pihole"].metadata[0].name, "pihole")

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

  portfolio_namespace   = try(kubernetes_namespace.app["portfolio"].metadata[0].name, "portfolio")
  qbittorrent_namespace = try(kubernetes_namespace.app["qbittorrent"].metadata[0].name, "qbittorrent")
  jellyfin_namespace    = try(kubernetes_namespace.app["jellyfin"].metadata[0].name, "jellyfin")
  pihole_namespace      = try(kubernetes_namespace.app["pihole"].metadata[0].name, "pihole")

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

  portfolio_namespace   = try(kubernetes_namespace.app["portfolio"].metadata[0].name, "portfolio")
  qbittorrent_namespace = try(kubernetes_namespace.app["qbittorrent"].metadata[0].name, "qbittorrent")
  jellyfin_namespace    = try(kubernetes_namespace.app["jellyfin"].metadata[0].name, "jellyfin")
  pihole_namespace      = try(kubernetes_namespace.app["pihole"].metadata[0].name, "pihole")

  tags = var.tags
}
