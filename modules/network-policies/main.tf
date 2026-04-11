# NetworkPolicies for application namespaces

# Ingress rules: Allow traffic from ingress controller
resource "kubernetes_network_policy" "portfolio" {
  count = var.enable_portfolio_netpol ? 1 : 0

  metadata {
    name      = "portfolio-netpol"
    namespace = var.portfolio_namespace
    labels = merge(
      var.tags,
      {
        app = "portfolio"
      }
    )
  }

  spec {
    # Apply to portfolio pods
    pod_selector {
      match_labels = {
        app = "portfolio"
      }
    }

    # Allow ingress from ingress-nginx controller
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
      }
      ports {
        port     = "80"
        protocol = "TCP"
      }
    }

    # Allow DNS egress
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    # Allow external HTTPS egress
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "qbittorrent" {
  count = var.enable_qbittorrent_netpol ? 1 : 0

  metadata {
    name      = "qbittorrent-netpol"
    namespace = var.qbittorrent_namespace
    labels = merge(
      var.tags,
      {
        app = "qbittorrent"
      }
    )
  }

  spec {
    pod_selector {
      match_labels = {
        app = "qbittorrent"
      }
    }

    # Allow ingress from ingress-nginx
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    # Allow DNS egress
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    # Allow all external egress (torrents need wide connectivity)
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "jellyfin" {
  count = var.enable_jellyfin_netpol ? 1 : 0

  metadata {
    name      = "jellyfin-netpol"
    namespace = var.jellyfin_namespace
    labels = merge(
      var.tags,
      {
        app = "jellyfin"
      }
    )
  }

  spec {
    pod_selector {
      match_labels = {
        app = "jellyfin"
      }
    }

    # Allow ingress from ingress-nginx
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
      }
      ports {
        port     = "8096"
        protocol = "TCP"
      }
    }

    # Allow DNS egress
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
    }

    # Allow external HTTPS egress
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "pihole" {
  count = var.enable_pihole_netpol ? 1 : 0

  metadata {
    name      = "pihole-netpol"
    namespace = var.pihole_namespace
    labels = merge(
      var.tags,
      {
        app = "pihole"
      }
    )
  }

  spec {
    pod_selector {
      match_labels = {
        app = "pihole"
      }
    }

    # Allow DNS ingress from anywhere in cluster
    ingress {
      from {
        pod_selector {}
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    # Allow DNS ingress from LAN (via MetalLB LoadBalancer)
    ingress {
      from {
        ip_block {
          cidr = "192.168.1.0/24"
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    # Allow DNS ingress from cluster nodes (kube-proxy SNAT)
    ingress {
      from {
        ip_block {
          cidr = "10.244.0.0/16"
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    # Allow web UI from ingress
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
      }
      ports {
        port     = "80"
        protocol = "TCP"
      }
    }

    # Allow web UI from LAN (via MetalLB LoadBalancer)
    ingress {
      from {
        ip_block {
          cidr = "192.168.1.0/24"
        }
      }
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }

    # Allow web UI from cluster nodes (kube-proxy SNAT)
    ingress {
      from {
        ip_block {
          cidr = "10.244.0.0/16"
        }
      }
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }

    # Allow DNS queries egress
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    # Allow HTTPS egress for updates
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}
