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

    # Allow ingress from traefik controller.
    # Portfolio listens on 8080 (Caddy). NetworkPolicy is enforced after
    # kube-proxy DNAT, so allow the pod port, not the service port.
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "traefik"
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

    # Allow ingress from traefik
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "traefik"
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
          cidr = "192.168.0.0/24"
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
            "kubernetes.io/metadata.name" = "traefik"
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
          cidr = "192.168.0.0/24"
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

resource "kubernetes_network_policy" "n8n" {
  count = var.enable_n8n_netpol ? 1 : 0

  metadata {
    name      = "n8n-netpol"
    namespace = var.n8n_namespace
    labels    = merge(var.tags, { app = "n8n" })
  }

  spec {
    pod_selector {}

    # Allow traefik to reach the n8n HTTP port
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "traefik"
          }
        }
      }
      ports {
        port     = "5678"
        protocol = "TCP"
      }
    }

    # Allow DNS resolution
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

    # Allow full external egress — n8n executes arbitrary webhook/API calls
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

# ---------------------------------------------------------------------------
# oauth2-proxy — allow ingress from traefik, egress to Keycloak + DNS
# ---------------------------------------------------------------------------
resource "kubernetes_network_policy" "oauth2_proxy" {
  count = var.enable_oauth2_proxy_netpol ? 1 : 0

  metadata {
    name      = "oauth2-proxy-netpol"
    namespace = var.oauth2_proxy_namespace
    labels    = merge(var.tags, { app = "oauth2-proxy" })
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "traefik"
          }
        }
      }
      ports {
        port     = "4180"
        protocol = "TCP"
      }
    }

    # Intra-namespace health probes
    ingress {
      from {
        pod_selector {}
      }
    }

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

    # Egress to Keycloak
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "keycloak"
          }
        }
      }
    }

    # Egress via traefik for OIDC discovery (sso.local.lan resolves via traefik)
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "traefik"
          }
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

# ---------------------------------------------------------------------------
# harbor — allow ingress from traefik + ci-builds, intra-namespace + Keycloak egress
# ---------------------------------------------------------------------------
resource "kubernetes_network_policy" "harbor" {
  count = var.enable_harbor_netpol ? 1 : 0

  metadata {
    name      = "harbor-netpol"
    namespace = var.harbor_namespace
    labels    = merge(var.tags, { app = "harbor" })
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "traefik"
          }
        }
      }
    }

    ingress {
      from {
        pod_selector {}
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ci-builds"
          }
        }
      }
    }

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

    egress {
      to {
        pod_selector {}
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "keycloak"
          }
        }
      }
    }

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "traefik"
          }
        }
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

# ---------------------------------------------------------------------------
# traefik — accept external HTTP/S, forward to all app namespaces
# ---------------------------------------------------------------------------
resource "kubernetes_network_policy" "traefik" {
  count = var.enable_traefik_netpol ? 1 : 0

  metadata {
    name      = "traefik-netpol"
    namespace = var.traefik_namespace
    labels    = merge(var.tags, { app = "traefik" })
  }

  spec {
    pod_selector {}

    # HTTP — Traefik listens on 8000 (service maps 80→8000).
    # NetworkPolicy is enforced after kube-proxy DNAT, so the
    # pod-level port must be allowed, not the service port.
    ingress {
      ports {
        port     = "8000"
        protocol = "TCP"
      }
      ports {
        port     = "8443"
        protocol = "TCP"
      }
    }

    # Validation webhook from kube-apiserver
    ingress {
      ports {
        port     = "8443"
        protocol = "TCP"
      }
    }

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

    # Forward to any backend namespace
    egress {
      to {
        namespace_selector {}
      }
    }

    policy_types = ["Ingress", "Egress"]
  }
}

# ===========================================================================
# AWX — Allow PostgreSQL ingress from AWX pods within the namespace
# ===========================================================================

resource "kubernetes_network_policy" "awx_postgres" {
  count = var.enable_awx_netpol ? 1 : 0

  metadata {
    name      = "allow-postgres-ingress"
    namespace = var.awx_namespace
    labels = merge(
      var.tags,
      {
        app = "awx"
      }
    )
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "postgres-15"
      }
    }

    ingress {
      from {
        pod_selector {
          match_labels = {
            "app.kubernetes.io/part-of" = "awx"
          }
        }
      }
      ports {
        port     = "5432"
        protocol = "TCP"
      }
    }

    policy_types = ["Ingress"]
  }
}
