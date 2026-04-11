################################################################################
# Docker-Apps Kubernetes Infrastructure as Code
# Manages all cluster and application deployments
################################################################################

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
}

resource "kubernetes_namespace" "jellyfin" {
  count = var.enable_jellyfin ? 1 : 0

  metadata {
    name = "jellyfin"
    labels = {
      name                                 = "jellyfin"
      "pod-security.kubernetes.io/enforce" = "baseline"
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
  count  = var.enable_portfolio ? 1 : 0
  source = "./modules/portfolio"

  namespace      = kubernetes_namespace.portfolio[0].metadata[0].name
  replicas       = var.portfolio_replicas
  cpu_request    = var.default_cpu_request
  memory_request = var.default_memory_request
  cpu_limit      = var.default_cpu_limit
  memory_limit   = var.default_memory_limit

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
  cpu_request    = "250m"
  memory_request = "512Mi"
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"

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

  tags = var.tags
}

module "pihole" {
  count  = var.enable_pihole ? 1 : 0
  source = "./modules/pihole"

  namespace      = kubernetes_namespace.pihole[0].metadata[0].name
  replicas       = 1
  web_password   = var.pihole_web_password
  timezone       = "UTC"
  cpu_request    = "100m"
  memory_request = "128Mi"
  cpu_limit      = "250m"
  memory_limit   = "512Mi"

  tags = var.tags
}

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  tags = var.tags
}

module "metrics_server" {
  count  = var.enable_metrics_server ? 1 : 0
  source = "./modules/metrics-server"
}

module "networking" {
  count  = var.enable_network_policies ? 1 : 0
  source = "./modules/networking"

  namespaces_with_policies = [
    "default",
    "portfolio",
    "jellyfin",
    "qbittorrent",
    "pihole"
  ]
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
