################################################################################
# Kubernetes Infrastructure as Code
# Manages all cluster and application deployments
################################################################################

locals {
  portfolio_host      = "portfolio.${var.ingress_base_domain}"
  jellyfin_host       = "jellyfin.${var.ingress_base_domain}"
  pihole_host         = "pihole.${var.ingress_base_domain}"
  grafana_host        = "grafana.${var.ingress_base_domain}"
  minio_host          = "minio.${var.ingress_base_domain}"
  vault_host          = "vault.${var.ingress_base_domain}"
  keycloak_host       = "sso.${var.ingress_base_domain}"
  matrix_host         = "chat.${var.ingress_base_domain}"
  matrix_synapse_host = trimspace(var.matrix_synapse_ingress_host) != "" ? trimspace(var.matrix_synapse_ingress_host) : local.matrix_host
  matrix_dendrite_host = trimspace(var.matrix_dendrite_ingress_host) != "" ? trimspace(var.matrix_dendrite_ingress_host) : local.matrix_host
  keycloak_issuer     = "https://sso.${var.ingress_base_domain}/realms/${var.keycloak_light_realm}"
  oauth2_proxy_host   = "auth.${var.ingress_base_domain}"
  n8n_host            = "n8n.${var.ingress_base_domain}"
  harbor_host         = "harbor.${var.ingress_base_domain}"
  rancher_host        = "rancher.${var.ingress_base_domain}"
  gitea_host          = "git.${var.ingress_base_domain}"
  awx_host            = "awx.${var.ingress_base_domain}"
  # Prefer explicit override, otherwise use the stable Pi-hole LoadBalancer IP
  private_dns_upstream = trimspace(var.private_dns_ip) != "" ? trimspace(var.private_dns_ip) : (
    var.enable_pihole ? trimspace(var.pihole_load_balancer_ip) : ""
  )

  # Namespaces that should receive LimitRange defaults
  limit_range_namespaces = compact([
    var.enable_portfolio ? "portfolio" : "",
    var.enable_jellyfin ? "jellyfin" : "",
    var.enable_pihole ? "pihole" : "",
    var.enable_keycloak_light ? "keycloak" : "",
    var.enable_harbor ? "harbor" : "",
    var.enable_gitea ? "git" : "",
    var.enable_awx ? "awx" : "",
    var.enable_buildkit ? "buildkit" : "",
    var.enable_n8n ? "n8n" : "",
    var.enable_matrix_synapse ? "matrix" : "",
    var.enable_matrix_dendrite ? "matrix" : "",
    var.enable_sabnzbd ? "sabnzbd" : "",
    var.enable_website_tracker ? "website-tracker-system" : "",
    var.enable_argo_workflows ? "argo" : "",
    var.enable_argo_events ? "argo-events" : "",
    var.enable_argo_rollouts ? "argo-rollouts" : "",
    var.enable_tekton_pipelines ? "tekton-pipelines" : "",
    var.enable_cloudflare_tunnel ? "cloudflare-tunnel" : "",
    "ci-builds",
    "oauth2-proxy",   # if oauth2-proxy module creates it
    "actions",         # Gitea Actions runners
  ])
}

# ---------------------------------------------------------------------------
# Infrastructure: cert-manager, traefik
# ---------------------------------------------------------------------------

# Read the cluster CA certificate so oauth2-proxy can verify Keycloak TLS
data "kubernetes_secret" "local_lan_ca" {
  metadata {
    name      = "local-lan-ca-secret"
    namespace = "cert-manager"
  }
}

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

  oauth2_proxy_url               = var.enable_oauth2_proxy ? "https://${local.oauth2_proxy_host}" : ""
  oauth2_proxy_auth_internal_url = var.enable_oauth2_proxy ? "http://oauth2-proxy.oauth2-proxy.svc.cluster.local" : ""
  oauth2_proxy_middleware        = var.enable_oauth2_proxy ? try(module.oauth2_proxy[0].auth_url, "oauth2-proxy-forward-auth@kubernetescrd") : ""

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

  oauth2_proxy_url               = var.enable_oauth2_proxy ? "https://${local.oauth2_proxy_host}" : ""
  oauth2_proxy_auth_internal_url = var.enable_oauth2_proxy ? "http://oauth2-proxy.oauth2-proxy.svc.cluster.local" : ""
  oauth2_proxy_middleware        = var.enable_oauth2_proxy ? try(module.oauth2_proxy[0].auth_url, "oauth2-proxy-forward-auth@kubernetescrd") : ""

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

module "keycloak_light" {
  count  = var.enable_keycloak_light ? 1 : 0
  source = "./modules/keycloak-light"

  namespace      = "keycloak"
  name           = "keycloak"
  image          = var.keycloak_light_image
  admin_user     = var.keycloak_light_admin_user
  admin_password = var.keycloak_light_admin_password
  ingress_host   = local.keycloak_host
  storage_size   = var.keycloak_light_storage_size
  storage_class  = var.keycloak_light_storage_class
  cpu_request    = var.keycloak_light_cpu_request
  memory_request = var.keycloak_light_memory_request
  cpu_limit      = var.keycloak_light_cpu_limit
  memory_limit   = var.keycloak_light_memory_limit

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

  oauth2_proxy_url               = var.enable_oauth2_proxy ? "https://${local.oauth2_proxy_host}" : ""
  oauth2_proxy_auth_internal_url = var.enable_oauth2_proxy ? "http://oauth2-proxy.oauth2-proxy.svc.cluster.local" : ""
  oauth2_proxy_middleware        = var.enable_oauth2_proxy ? try(module.oauth2_proxy[0].auth_url, "oauth2-proxy-forward-auth@kubernetescrd") : ""

  tags = var.tags
}

module "matrix_synapse" {
  count  = var.enable_matrix_synapse ? 1 : 0
  source = "./modules/matrix-synapse"

  namespace       = "matrix"
  name            = "matrix-synapse"
  image           = var.matrix_synapse_image
  server_name     = trimspace(var.matrix_synapse_server_name) != "" ? trimspace(var.matrix_synapse_server_name) : local.matrix_synapse_host
  public_base_url = trimspace(var.matrix_synapse_public_base_url) != "" ? trimspace(var.matrix_synapse_public_base_url) : "https://${local.matrix_synapse_host}"
  report_stats    = var.matrix_synapse_report_stats
  storage_size    = var.matrix_synapse_storage_size
  storage_class   = var.matrix_synapse_storage_class
  ingress_host    = local.matrix_synapse_host
  cluster_issuer  = var.matrix_synapse_cluster_issuer
  cpu_request     = var.matrix_synapse_cpu_request
  memory_request  = var.matrix_synapse_memory_request
  cpu_limit       = var.matrix_synapse_cpu_limit
  memory_limit    = var.matrix_synapse_memory_limit

  registration_shared_secret = var.matrix_synapse_registration_shared_secret
  bootstrap_admin_enabled    = var.matrix_synapse_bootstrap_admin_enabled
  bootstrap_admin_username   = var.matrix_synapse_bootstrap_admin_username
  bootstrap_admin_password   = var.matrix_synapse_bootstrap_admin_password

  oidc_enabled       = var.matrix_synapse_oidc_enabled
  oidc_issuer_url    = trimspace(var.matrix_synapse_oidc_issuer_url) != "" ? trimspace(var.matrix_synapse_oidc_issuer_url) : try(module.keycloak_light[0].issuer_url, local.keycloak_issuer)
  oidc_client_id     = var.matrix_synapse_oidc_client_id
  oidc_client_secret = var.matrix_synapse_oidc_client_secret
  oidc_scopes        = var.matrix_synapse_oidc_scopes

  federation_enabled          = var.matrix_synapse_federation_enabled
  federation_domain_whitelist = var.matrix_synapse_federation_domain_whitelist
  well_known_enabled          = var.matrix_synapse_well_known_enabled

  tags = var.tags
}

module "matrix_dendrite" {
  count  = var.enable_matrix_dendrite ? 1 : 0
  source = "./modules/matrix-dendrite"

  namespace       = "matrix"
  name            = "matrix-dendrite"
  image           = var.matrix_dendrite_image
  server_name     = trimspace(var.matrix_dendrite_server_name) != "" ? trimspace(var.matrix_dendrite_server_name) : local.matrix_dendrite_host
  public_base_url = trimspace(var.matrix_dendrite_public_base_url) != "" ? trimspace(var.matrix_dendrite_public_base_url) : "https://${local.matrix_dendrite_host}"
  storage_size    = var.matrix_dendrite_storage_size
  storage_class   = var.matrix_dendrite_storage_class
  ingress_host    = local.matrix_dendrite_host
  cluster_issuer  = var.matrix_dendrite_cluster_issuer
  cpu_request     = var.matrix_dendrite_cpu_request
  memory_request  = var.matrix_dendrite_memory_request
  cpu_limit       = var.matrix_dendrite_cpu_limit
  memory_limit    = var.matrix_dendrite_memory_limit

  registration_shared_secret = var.matrix_dendrite_registration_shared_secret
  bootstrap_admin_enabled    = var.matrix_dendrite_bootstrap_admin_enabled
  bootstrap_admin_username   = var.matrix_dendrite_bootstrap_admin_username
  bootstrap_admin_password   = var.matrix_dendrite_bootstrap_admin_password

  oidc_enabled       = var.matrix_dendrite_oidc_enabled
  oidc_issuer_url    = trimspace(var.matrix_dendrite_oidc_issuer_url) != "" ? trimspace(var.matrix_dendrite_oidc_issuer_url) : try(module.keycloak_light[0].issuer_url, local.keycloak_issuer)
  oidc_client_id     = var.matrix_dendrite_oidc_client_id
  oidc_client_secret = var.matrix_dendrite_oidc_client_secret
  oidc_scopes        = var.matrix_dendrite_oidc_scopes

  federation_enabled          = var.matrix_dendrite_federation_enabled
  federation_domain_whitelist = var.matrix_dendrite_federation_domain_whitelist
  well_known_enabled          = var.matrix_dendrite_well_known_enabled

  tags = var.tags
}

module "cloudflare_tunnel" {
  count  = var.enable_cloudflare_tunnel ? 1 : 0
  source = "./modules/cloudflare-tunnel"

  namespace                = "cloudflare-tunnel"
  name                     = "cloudflared"
  image                    = var.cloudflare_tunnel_image
  tunnel_token_secret_name = var.cloudflare_tunnel_secret_name

  tags = var.tags

  depends_on = [module.traefik]
}

module "oauth2_proxy" {
  count  = var.enable_oauth2_proxy ? 1 : 0
  source = "./modules/oauth2-proxy"

  release_name                  = "oauth2-proxy"
  chart_version                 = var.oauth2_proxy_chart_version
  oauth2_provider               = var.oauth2_proxy_provider
  email_domain                  = var.oauth2_proxy_email_domain
  client_id                     = var.oauth2_proxy_client_id
  client_secret                 = var.oauth2_proxy_client_secret
  cookie_secret                 = var.oauth2_proxy_cookie_secret
  ingress_host                  = local.oauth2_proxy_host
  oidc_issuer_url               = try(module.keycloak_light[0].issuer_url, local.keycloak_issuer)
  insecure_skip_oidc_tls_verify = var.oauth2_proxy_insecure_skip_oidc_tls_verify
  oidc_ca_cert_pem              = data.kubernetes_secret.local_lan_ca.data["tls.crt"]
  allowed_group                 = "homelab-admins"
  oidc_extra_scope              = "groups"

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

# Modules
module "portfolio" {
  count  = var.enable_portfolio && var.manage_portfolio_workload ? 1 : 0
  source = "./modules/portfolio"

  namespace             = kubernetes_namespace.portfolio[0].metadata[0].name
  image                 = var.portfolio_image
  image_pull_secrets    = var.portfolio_image_pull_secrets
  replicas              = var.portfolio_replicas
  cpu_request           = var.default_cpu_request
  memory_request        = var.default_memory_request
  cpu_limit             = var.default_cpu_limit
  memory_limit          = var.default_memory_limit
  ingress_host          = local.portfolio_host

  oauth2_proxy_middleware = var.enable_oauth2_proxy ? try(module.oauth2_proxy[0].auth_url, "oauth2-proxy-forward-auth@kubernetescrd") : ""

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
  load_balancer_ip = var.jellyfin_load_balancer_ip
  gpu_count      = var.jellyfin_gpu_count
  cpu_request    = "250m"
  memory_request = "512Mi"
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  ingress_host   = local.jellyfin_host

  oauth2_proxy_url               = var.enable_oauth2_proxy ? "https://${local.oauth2_proxy_host}" : ""
  oauth2_proxy_auth_internal_url = var.enable_oauth2_proxy ? "http://oauth2-proxy.oauth2-proxy.svc.cluster.local" : ""
  oauth2_proxy_middleware        = var.enable_oauth2_proxy ? try(module.oauth2_proxy[0].auth_url, "oauth2-proxy-forward-auth@kubernetescrd") : ""

  tags = var.tags
}

module "pihole" {
  count  = var.enable_pihole ? 1 : 0
  source = "./modules/pihole"

  namespace           = kubernetes_namespace.pihole[0].metadata[0].name
  load_balancer_ip    = var.pihole_load_balancer_ip
  ingress_ip          = var.traefik_load_balancer_ip
  replicas            = 1
  web_password        = var.pihole_web_password
  timezone            = "UTC"
  cpu_request         = "100m"
  memory_request      = "128Mi"
  cpu_limit           = "250m"
  memory_limit        = "512Mi"
  ingress_host        = local.pihole_host
  dns_wildcard_domain = var.ingress_base_domain

  oauth2_proxy_url               = var.enable_oauth2_proxy ? "https://${local.oauth2_proxy_host}" : ""
  oauth2_proxy_auth_internal_url = var.enable_oauth2_proxy ? "http://oauth2-proxy.oauth2-proxy.svc.cluster.local" : ""

  tags = var.tags
}

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  grafana_service_name           = "monitor-grafana"
  grafana_host                   = local.grafana_host
  oauth2_proxy_url               = var.enable_oauth2_proxy ? "https://${local.oauth2_proxy_host}" : ""
  oauth2_proxy_auth_internal_url = var.enable_oauth2_proxy ? "http://oauth2-proxy.oauth2-proxy.svc.cluster.local" : ""
  oauth2_proxy_middleware        = var.enable_oauth2_proxy ? try(module.oauth2_proxy[0].auth_url, "oauth2-proxy-forward-auth@kubernetescrd") : ""

  tags = var.tags
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
    var.enable_loki ? "loki" : "",
    var.enable_minio ? "minio" : "",
    var.enable_velero ? "velero" : "",
    var.enable_vault ? "vault" : "",
    var.enable_external_secrets ? "external-secrets" : "",
    var.enable_tempo ? "tracing" : "",
    var.enable_n8n ? "n8n" : "",
    var.enable_matrix_synapse ? "matrix" : "",
    # monitoring has its own namespace-specific policies in the monitoring module
    # traefik should not receive a blanket default-deny without explicit allow rules
    var.enable_cert_manager ? "cert-manager" : "",
    var.enable_rancher ? "cattle-system" : "",
    var.enable_traefik ? "traefik" : "",
    var.enable_harbor ? "harbor" : "",
    var.enable_gitea ? "git" : "",
    var.enable_keda ? "keda" : "",
    var.enable_falco ? "falco" : "",
    var.enable_buildkit ? "buildkit" : "",
    var.enable_sabnzbd ? "sabnzbd" : "",
    var.enable_argo_workflows ? "argo" : "",
    var.enable_tekton_pipelines ? "tekton-pipelines" : "",
    var.enable_linkerd ? "linkerd" : "",
    var.enable_awx ? "awx" : "",
  ])
}

# Resource Quotas
module "resource_quotas" {
  count  = var.enable_resource_quotas ? 1 : 0
  source = "./modules/resource-quotas"

  enable_portfolio_quota = var.enable_portfolio
  enable_jellyfin_quota  = var.enable_jellyfin
  enable_pihole_quota    = var.enable_pihole
  enable_argo_quota      = var.enable_argo_workflows
  enable_gitea_quota     = var.enable_gitea
  enable_harbor_quota    = var.enable_harbor
  enable_buildkit_quota  = var.enable_buildkit
  enable_awx_quota       = var.enable_awx
  enable_matrix_quota    = var.enable_matrix_synapse
  enable_n8n_quota       = var.enable_n8n

  tags = var.tags
}

# ---- LimitRanges — Default CPU/Memory for every namespace ----
# Ensures no container runs without resource constraints.
module "limit_ranges" {
  for_each = toset(local.limit_range_namespaces)
  source   = "./modules/limit-range"

  namespace = each.key
  tags      = var.tags
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

  enable_oauth2_proxy_netpol  = var.enable_oauth2_proxy
  oauth2_proxy_namespace      = "oauth2-proxy"
  enable_harbor_netpol        = true
  harbor_namespace            = "harbor"
  enable_traefik_netpol       = var.enable_traefik
  traefik_namespace           = "traefik"

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
# Platform: Rancher, Traefik, MetalLB, Linkerd, KEDA
# ---------------------------------------------------------------------------

module "rancher" {
  count  = var.enable_rancher ? 1 : 0
  source = "./modules/rancher"

  tags = var.tags

  depends_on = [module.cert_manager]
}

module "traefik" {
  count  = var.enable_traefik ? 1 : 0
  source = "./modules/traefik"

  release_name  = "traefik"
  chart_version = var.traefik_chart_version
  replicas      = var.traefik_replicas
  service_type  = var.traefik_service_type
  load_balancer_ip = var.traefik_load_balancer_ip

  tags = var.tags

  # Traefik's LoadBalancer service depends on MetalLB being ready first.
  # This prevents the Helm install from timing out while waiting for an
  # external IP that MetalLB hasn't provisioned yet.
}

module "linkerd" {
  count  = var.enable_linkerd ? 1 : 0
  source = "./modules/linkerd"

  enable_linkerd_viz = var.enable_linkerd_viz

  tags = var.tags
}

module "keda" {
  count  = var.enable_keda ? 1 : 0
  source = "./modules/keda"

  release_name  = "keda"
  chart_version = var.keda_chart_version

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Registry & Git: Harbor, Gitea
# ---------------------------------------------------------------------------

module "harbor" {
  count  = var.enable_harbor ? 1 : 0
  source = "./modules/harbor"

  release_name     = "harbor"
  chart_version    = var.harbor_chart_version
  ingress_host     = local.harbor_host
  ingress_class_name = var.harbor_ingress_class_name
  admin_password   = var.harbor_admin_password
  storage_class    = var.harbor_storage_class

  tags = var.tags
}

module "gitea" {
  count  = var.enable_gitea ? 1 : 0
  source = "./modules/gitea"

  release_name      = "gitea"
  chart_version     = var.gitea_chart_version
  image_tag         = var.gitea_image_tag
  ingress_host      = local.gitea_host
  ingress_class_name = var.gitea_ingress_class_name
  admin_username    = var.gitea_admin_username
  admin_password    = var.gitea_admin_password
  admin_email       = var.gitea_admin_email
  postgresql_password = var.gitea_postgresql_password
  storage_size      = var.gitea_storage_size
  storage_class     = var.gitea_storage_class

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Rancher ecosystem: Fleet, Turtles
# ---------------------------------------------------------------------------

module "fleet" {
  count  = var.enable_fleet ? 1 : 0
  source = "./modules/fleet"

  release_name              = "fleet"
  chart_version             = var.fleet_chart_version
  fleet_crd_chart_version   = var.fleet_chart_version
  rancher_url               = "https://${local.rancher_host}"

  tags = var.tags

  depends_on = [module.rancher]
}

module "rancher_turtles" {
  count  = var.enable_rancher_turtles ? 1 : 0
  source = "./modules/rancher-turtles"

  release_name  = "rancher-turtles"
  chart_version = var.rancher_turtles_chart_version

  tags = var.tags

  depends_on = [module.rancher]
}

# ---------------------------------------------------------------------------
# CI/CD: Argo Workflows, Tekton
# ---------------------------------------------------------------------------

module "argo_workflows" {
  count  = var.enable_argo_workflows ? 1 : 0
  source = "./modules/argo-workflows"

  enable_argo_events   = var.enable_argo_events
  enable_argo_rollouts = var.enable_argo_rollouts

  tags = var.tags
}

module "tekton_pipelines" {
  count  = var.enable_tekton_pipelines ? 1 : 0
  source = "./modules/tekton-pipelines"

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Security: Falco, Sealed Secrets
# ---------------------------------------------------------------------------

module "falco" {
  count  = var.enable_falco ? 1 : 0
  source = "./modules/falco"

  release_name  = "falco"
  chart_version = var.falco_chart_version

  tags = var.tags
}

module "sealed_secrets" {
  count  = var.enable_sealed_secrets ? 1 : 0
  source = "./modules/sealed-secrets"

  image = var.sealed_secrets_image

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Automation: AWX (Ansible Automation Platform upstream)
# ---------------------------------------------------------------------------

module "awx" {
  count  = var.enable_awx ? 1 : 0
  source = "./modules/awx"

  namespace               = "awx"
  release_name            = "awx-operator"
  operator_chart_version  = var.awx_operator_chart_version
  awx_instance_name       = "awx"
  awx_image_version       = var.awx_image_version
  admin_user              = var.awx_admin_user
  admin_password          = var.awx_admin_password
  admin_email             = var.awx_admin_email
  ingress_host            = "awx.${var.ingress_base_domain}"
  ingress_class_name      = "traefik"
  cluster_issuer          = "local-lan-ca"
  postgres_storage_class  = var.awx_postgres_storage_class
  postgres_storage_size   = var.awx_postgres_storage_size
  web_replicas            = var.awx_web_replicas
  task_replicas           = var.awx_task_replicas

  tags = var.tags

  depends_on = [module.cert_manager]
}

# ---------------------------------------------------------------------------
# Build & Apps: BuildKit, Sabnzbd, Website Tracker
# ---------------------------------------------------------------------------

module "buildkit" {
  count  = var.enable_buildkit ? 1 : 0
  source = "./modules/buildkit"

  tags = var.tags
}

module "sabnzbd" {
  count  = var.enable_sabnzbd ? 1 : 0
  source = "./modules/sabnzbd"

  tags = var.tags
}

module "website_tracker" {
  count  = var.enable_website_tracker ? 1 : 0
  source = "./modules/website-tracker"

  tags = var.tags
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

