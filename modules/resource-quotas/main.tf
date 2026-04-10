# Resource Quotas to prevent resource exhaustion in application namespaces

resource "kubernetes_resource_quota" "portfolio" {
  count = var.enable_portfolio_quota ? 1 : 0

  metadata {
    name      = "portfolio-quota"
    namespace = var.portfolio_namespace
    labels = merge(
      var.tags,
      {
        app = "portfolio"
      }
    )
  }

  spec {
    hard = {
      "pods"                = var.portfolio_pod_limit
      "requests.cpu"        = var.portfolio_cpu_request_quota
      "requests.memory"     = var.portfolio_memory_request_quota
      "limits.cpu"          = var.portfolio_cpu_limit_quota
      "limits.memory"       = var.portfolio_memory_limit_quota
      "persistentvolumeclaims" = "5"
    }
  }
}

resource "kubernetes_resource_quota" "qbittorrent" {
  count = var.enable_qbittorrent_quota ? 1 : 0

  metadata {
    name      = "qbittorrent-quota"
    namespace = var.qbittorrent_namespace
    labels = merge(
      var.tags,
      {
        app = "qbittorrent"
      }
    )
  }

  spec {
    hard = {
      "pods"                = var.qbittorrent_pod_limit
      "requests.cpu"        = var.qbittorrent_cpu_request_quota
      "requests.memory"     = var.qbittorrent_memory_request_quota
      "limits.cpu"          = var.qbittorrent_cpu_limit_quota
      "limits.memory"       = var.qbittorrent_memory_limit_quota
      "persistentvolumeclaims" = "5"
    }
  }
}

resource "kubernetes_resource_quota" "jellyfin" {
  count = var.enable_jellyfin_quota ? 1 : 0

  metadata {
    name      = "jellyfin-quota"
    namespace = var.jellyfin_namespace
    labels = merge(
      var.tags,
      {
        app = "jellyfin"
      }
    )
  }

  spec {
    hard = {
      "pods"                = var.jellyfin_pod_limit
      "requests.cpu"        = var.jellyfin_cpu_request_quota
      "requests.memory"     = var.jellyfin_memory_request_quota
      "limits.cpu"          = var.jellyfin_cpu_limit_quota
      "limits.memory"       = var.jellyfin_memory_limit_quota
      "persistentvolumeclaims" = "10"
    }
  }
}

resource "kubernetes_resource_quota" "pihole" {
  count = var.enable_pihole_quota ? 1 : 0

  metadata {
    name      = "pihole-quota"
    namespace = var.pihole_namespace
    labels = merge(
      var.tags,
      {
        app = "pihole"
      }
    )
  }

  spec {
    hard = {
      "pods"            = var.pihole_pod_limit
      "requests.cpu"    = var.pihole_cpu_request_quota
      "requests.memory" = var.pihole_memory_request_quota
      "limits.cpu"      = var.pihole_cpu_limit_quota
      "limits.memory"   = var.pihole_memory_limit_quota
    }
  }
}
