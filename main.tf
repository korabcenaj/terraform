################################################################################
# Docker-Apps Kubernetes Infrastructure as Code
# Manages all cluster and application deployments
################################################################################

locals {
  portfolio_host    = "portfolio.${var.ingress_base_domain}"
  jellyfin_host     = "jellyfin.${var.ingress_base_domain}"
  pihole_host       = "pihole.${var.ingress_base_domain}"
  grafana_host      = "grafana.${var.ingress_base_domain}"
  prometheus_host   = "prometheus.${var.ingress_base_domain}"
  minio_host        = "minio.${var.ingress_base_domain}"
  argocd_host       = "argocd.${var.ingress_base_domain}"
  vault_host        = "vault.${var.ingress_base_domain}"
  keycloak_host     = "sso.${var.ingress_base_domain}"
  keycloak_issuer   = "https://sso.${var.ingress_base_domain}/realms/${var.keycloak_realm}"
  oauth2_proxy_host = "auth.${var.ingress_base_domain}"
  n8n_host          = "n8n.${var.ingress_base_domain}"
    harbor_host       = "harbor.${var.ingress_base_domain}"
  # Prefer explicit override, otherwise use the stable Pi-hole LoadBalancer IP
  # (router DNS) so CoreDNS forwarding survives pod/service IP churn.
  private_dns_upstream = trimspace(var.private_dns_ip) != "" ? trimspace(var.private_dns_ip) : (
    var.enable_pihole ? trimspace(var.pihole_load_balancer_ip) : ""
  )
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

  alertmanager_enabled         = var.alertmanager_enabled
  alertmanager_webhook_url     = var.alertmanager_webhook_url
  alertmanager_repeat_interval = var.alertmanager_repeat_interval
  create_alert_rules           = var.create_alert_rules

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

  release_name           = "velero"
  chart_version          = var.velero_chart_version
  bucket_name            = var.velero_bucket_name
  s3_url                 = var.velero_s3_url
  access_key             = var.minio_root_user
  secret_key             = var.minio_root_password
  create_backup_schedule = var.velero_create_backup_schedule
  schedule_name          = var.velero_schedule_name
  schedule_cron          = var.velero_schedule_cron
  backup_namespaces      = var.velero_backup_namespaces
  backup_ttl             = var.velero_backup_ttl

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
  vault_auth_method                 = var.external_secrets_vault_auth_method
  vault_kubernetes_mount_path       = var.external_secrets_vault_kubernetes_mount_path
  vault_kubernetes_role             = var.external_secrets_vault_kubernetes_role

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

  create_bootstrap_app_project = var.argocd_create_app_project
  bootstrap_project_name       = var.argocd_project_name
  create_bootstrap_application = var.argocd_create_bootstrap_app
  bootstrap_app_name           = var.argocd_bootstrap_app_name
  bootstrap_repo_url           = var.argocd_bootstrap_repo_url
  bootstrap_repo_revision      = var.argocd_bootstrap_repo_revision
  bootstrap_repo_path          = var.argocd_bootstrap_repo_path
  bootstrap_auto_sync          = var.argocd_bootstrap_auto_sync

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
  grafana_client_id          = var.grafana_oidc_client_id
  grafana_client_secret      = var.grafana_oidc_client_secret
  grafana_redirect_uris      = ["https://${local.grafana_host}/login/generic_oauth"]
  grafana_web_origins        = ["https://${local.grafana_host}"]
  harbor_client_id           = var.harbor_oidc_client_id
  harbor_client_secret       = var.harbor_oidc_client_secret
  harbor_redirect_uris       = ["https://${local.harbor_host}/c/oidc/callback"]
  harbor_web_origins         = ["https://${local.harbor_host}"]
  oauth2_proxy_client_id     = var.oauth2_proxy_client_id
  oauth2_proxy_client_secret = var.oauth2_proxy_client_secret
  oauth2_proxy_redirect_uris = ["https://${local.oauth2_proxy_host}/oauth2/callback"]
  oauth2_proxy_web_origins   = ["https://${local.oauth2_proxy_host}"]

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

module "n8n" {
  count  = var.enable_n8n ? 1 : 0
  source = "./modules/n8n"

  release_name   = "n8n"
  chart_version  = var.n8n_chart_version
  encryption_key = var.n8n_encryption_key
  storage_size   = var.n8n_storage_size
  storage_class  = var.n8n_storage_class
  ingress_host   = local.n8n_host
  timezone       = var.n8n_timezone
  webhook_url    = var.n8n_webhook_url

  tags = var.tags
}

module "oauth2_proxy" {
  count  = var.enable_oauth2_proxy ? 1 : 0
  source = "./modules/oauth2-proxy"

  release_name     = "oauth2-proxy"
  chart_version    = var.oauth2_proxy_chart_version
  oauth2_provider  = var.oauth2_proxy_provider
  email_domain     = var.oauth2_proxy_email_domain
  client_id        = var.oauth2_proxy_client_id
  client_secret    = var.oauth2_proxy_client_secret
  cookie_secret    = var.oauth2_proxy_cookie_secret
  ingress_host     = local.oauth2_proxy_host
  oidc_issuer_url  = local.keycloak_issuer

  tags = var.tags
}



# ---------------------------------------------------------------------------
# AI Orchestrator — namespace + policies (workloads owned by Argo CD)
# ---------------------------------------------------------------------------

module "ai_orchestrator" {
  count  = var.enable_ai_orchestrator ? 1 : 0
  source = "./modules/ai-orchestrator"

  namespace        = "ai-orchestrator"
  api_gateway_port = var.ai_orchestrator_api_gateway_port
  cpu_request      = var.ai_orchestrator_cpu_request
  memory_request   = var.ai_orchestrator_memory_request
  cpu_limit        = var.ai_orchestrator_cpu_limit
  memory_limit     = var.ai_orchestrator_memory_limit
  gpu_limit        = var.ai_orchestrator_gpu_limit
  max_pods         = var.ai_orchestrator_max_pods
  max_pvcs         = var.ai_orchestrator_max_pvcs

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

resource "kubernetes_namespace" "qbittorrent" {
  count = var.enable_qbittorrent ? 1 : 0

  metadata {
    name = "qbittorrent"
    labels = {
      name = "qbittorrent"
      # linuxserver image writes to /config; privileged PSS avoids seccomp conflicts
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
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

module "pihole" {
  count  = var.enable_pihole ? 1 : 0
  source = "./modules/pihole"

  namespace           = kubernetes_namespace.pihole[0].metadata[0].name
  load_balancer_ip    = var.pihole_load_balancer_ip
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

module "qbittorrent" {
  count  = var.enable_qbittorrent ? 1 : 0
  source = "./modules/qbittorrent"

  namespace      = kubernetes_namespace.qbittorrent[0].metadata[0].name
  replicas       = var.qbittorrent_replicas
  image          = var.qbittorrent_image
  storage_class  = var.qbittorrent_storage_class
  config_size    = var.qbittorrent_config_size
  downloads_size = var.qbittorrent_downloads_size
  node_name      = var.qbittorrent_node_name
  timezone       = var.qbittorrent_timezone
  cpu_request    = "100m"
  memory_request = "128Mi"
  cpu_limit      = "500m"
  memory_limit   = "512Mi"
  ingress_host   = "qbittorrent.${var.ingress_base_domain}"

  tags = var.tags
}

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  grafana_service_name    = var.enable_kube_prometheus_stack ? try(module.kube_prometheus_stack[0].grafana_service_name, "monitor-grafana") : "monitor-grafana"
  prometheus_service_name = var.enable_kube_prometheus_stack ? try(module.kube_prometheus_stack[0].prometheus_service_name, "monitor-kube-prometheus-st-prometheus") : "monitor-kube-prometheus-st-prometheus"
  grafana_host            = local.grafana_host
  prometheus_host         = local.prometheus_host
  oauth2_proxy_url               = var.enable_oauth2_proxy ? "https://${local.oauth2_proxy_host}" : ""
  oauth2_proxy_auth_internal_url = var.enable_oauth2_proxy ? "http://oauth2-proxy.oauth2-proxy.svc.cluster.local" : ""

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
    var.enable_pihole ? "pihole" : "",
    var.enable_loki ? "logging" : "",
    var.enable_minio ? "minio" : "",
    var.enable_velero ? "velero" : "",
    var.enable_vault ? "vault" : "",
    var.enable_external_secrets ? "external-secrets" : "",
    var.enable_argocd ? "argocd" : "",
    var.enable_tempo ? "tracing" : "",
    var.enable_n8n ? "n8n" : "",
    # monitoring has its own namespace-specific policies in the monitoring module
    # ingress-nginx should not receive a blanket default-deny without explicit allow rules
    var.enable_cert_manager ? "cert-manager" : "",
    var.enable_ai_orchestrator ? "ai-orchestrator" : "",
    var.enable_qbittorrent ? "qbittorrent" : "",
  ])
}

# Resource Quotas
module "resource_quotas" {
  count  = var.enable_resource_quotas ? 1 : 0
  source = "./modules/resource-quotas"

  enable_portfolio_quota = var.enable_portfolio
  enable_jellyfin_quota  = var.enable_jellyfin
  enable_pihole_quota    = var.enable_pihole

  portfolio_namespace = try(kubernetes_namespace.portfolio[0].metadata[0].name, "portfolio")
  jellyfin_namespace  = try(kubernetes_namespace.jellyfin[0].metadata[0].name, "jellyfin")
  pihole_namespace    = try(kubernetes_namespace.pihole[0].metadata[0].name, "pihole")

  tags = var.tags
}

# Network Policies
module "network_policies" {
  count  = var.enable_network_policies ? 1 : 0
  source = "./modules/network-policies"

  enable_portfolio_netpol = var.enable_portfolio
  enable_jellyfin_netpol  = var.enable_jellyfin
  enable_pihole_netpol    = var.enable_pihole
  enable_n8n_netpol       = var.enable_n8n

  portfolio_namespace = try(kubernetes_namespace.portfolio[0].metadata[0].name, "portfolio")
  jellyfin_namespace  = try(kubernetes_namespace.jellyfin[0].metadata[0].name, "jellyfin")
  pihole_namespace    = try(kubernetes_namespace.pihole[0].metadata[0].name, "pihole")
  n8n_namespace       = try(module.n8n[0].namespace, "n8n")

  tags = var.tags
}

# Pod Disruption Budgets
module "pod_disruption_budgets" {
  count  = var.enable_pod_disruption_budgets ? 1 : 0
  source = "./modules/pod-disruption-budgets"

  enable_portfolio_pdb = var.enable_portfolio
  enable_jellyfin_pdb  = var.enable_jellyfin
  enable_pihole_pdb    = var.enable_pihole

  portfolio_namespace = try(kubernetes_namespace.portfolio[0].metadata[0].name, "portfolio")
  jellyfin_namespace  = try(kubernetes_namespace.jellyfin[0].metadata[0].name, "jellyfin")
  pihole_namespace    = try(kubernetes_namespace.pihole[0].metadata[0].name, "pihole")

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Skills Dashboard
# ---------------------------------------------------------------------------

module "skills_dashboard" {
  count  = var.enable_skills_dashboard ? 1 : 0
  source = "./modules/skills-dashboard"

  release_name       = "skills-dashboard"
  namespace          = "default"
  replicas           = 2
  host               = var.skills_dashboard_host != "" ? var.skills_dashboard_host : "skills.${var.ingress_base_domain}"
  ingress_class_name = "nginx"
  enable_ingress     = true
  tls_enabled        = var.enable_cert_manager
  annotations = {
    "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# CI / Build infrastructure
# ---------------------------------------------------------------------------

# Dedicated namespace for kaniko image-build jobs.
resource "kubernetes_namespace" "ci_builds" {
  metadata {
    name = "ci-builds"
    labels = merge(var.tags, {
      name = "ci-builds"
    })
  }
  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

# Service account used by the GitHub Actions runner (or any CI agent) to
# submit kaniko Jobs.  It intentionally lives in the default namespace so that
# existing kubeconfig secrets / runner configs don't need to change.
resource "kubernetes_service_account_v1" "kaniko_builder" {
  metadata {
    name      = "kaniko-builder"
    namespace = "default"
    labels    = var.tags
  }
  automount_service_account_token = false
}

# Least-privilege Role: only the operations the build script actually needs.
resource "kubernetes_role_v1" "kaniko_builder" {
  metadata {
    name      = "kaniko-builder"
    namespace = kubernetes_namespace.ci_builds.metadata[0].name
    labels    = var.tags
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["create", "get", "delete", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/log"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding_v1" "kaniko_builder" {
  metadata {
    name      = "kaniko-builder"
    namespace = kubernetes_namespace.ci_builds.metadata[0].name
    labels    = var.tags
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.kaniko_builder.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.kaniko_builder.metadata[0].name
    namespace = kubernetes_service_account_v1.kaniko_builder.metadata[0].namespace
  }
}

# ---------------------------------------------------------------------------
# Control-plane scheduling
# ---------------------------------------------------------------------------

# Prevent workload pods from landing on the control-plane node.
# The taint tolerations required by kube-system DaemonSets are already present
# in those pods so system components are unaffected.
resource "kubernetes_node_taint" "control_plane_no_schedule" {
  count = var.enable_control_plane_taint ? 1 : 0

  metadata {
    name = var.control_plane_node_name
  }

  taint {
    key    = "node-role.kubernetes.io/control-plane"
    value  = ""
    effect = "NoSchedule"
  }
}

