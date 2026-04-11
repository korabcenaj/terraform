# Pod Disruption Budgets for high availability

resource "kubernetes_pod_disruption_budget_v1" "portfolio" {
  count = var.enable_portfolio_pdb ? 1 : 0

  metadata {
    name      = "portfolio-pdb"
    namespace = var.portfolio_namespace
    labels = merge(
      var.tags,
      {
        app = "portfolio"
      }
    )
  }

  spec {
    max_unavailable = var.portfolio_max_unavailable
    selector {
      match_labels = {
        app = "portfolio"
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "qbittorrent" {
  count = var.enable_qbittorrent_pdb ? 1 : 0

  metadata {
    name      = "qbittorrent-pdb"
    namespace = var.qbittorrent_namespace
    labels = merge(
      var.tags,
      {
        app = "qbittorrent"
      }
    )
  }

  spec {
    max_unavailable = var.qbittorrent_max_unavailable
    selector {
      match_labels = {
        app = "qbittorrent"
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "jellyfin" {
  count = var.enable_jellyfin_pdb ? 1 : 0

  metadata {
    name      = "jellyfin-pdb"
    namespace = var.jellyfin_namespace
    labels = merge(
      var.tags,
      {
        app = "jellyfin"
      }
    )
  }

  spec {
    max_unavailable = var.jellyfin_max_unavailable
    selector {
      match_labels = {
        app = "jellyfin"
      }
    }
  }
}

resource "kubernetes_pod_disruption_budget_v1" "pihole" {
  count = var.enable_pihole_pdb ? 1 : 0

  metadata {
    name      = "pihole-pdb"
    namespace = var.pihole_namespace
    labels = merge(
      var.tags,
      {
        app = "pihole"
      }
    )
  }

  spec {
    max_unavailable = var.pihole_max_unavailable
    selector {
      match_labels = {
        app = "pihole"
      }
    }
  }
}
