# Monitoring stack is already deployed via Helm charts in the cluster
# This module serves as a placeholder and documentation for monitoring configuration

# In production, we would manage Grafana here
# For now, we reference the existing monitoring namespace

data "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Example: Reference existing Grafana installation
data "kubernetes_service" "grafana" {
  metadata {
    name      = var.grafana_service_name
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
  }
}

# Ingress for Grafana
resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "monitoring-grafana"
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer" = "local-lan-ca"
    }
  }

  spec {
    ingress_class_name = "traefik"

    tls {
      hosts       = [var.grafana_host]
      secret_name = "grafana-local-lan-tls"
    }

    rule {
      host = var.grafana_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.grafana_service_name
              port {
                number = var.grafana_service_port
              }
            }
          }
        }
      }
    }
  }
}

# Default deny all ingress in monitoring namespace
resource "kubernetes_network_policy" "monitoring_default_deny" {
  metadata {
    name      = "default-deny-ingress"
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

# Allow traefik to reach Grafana
resource "kubernetes_network_policy" "monitoring_allow_from_ingress" {
  metadata {
    name      = "allow-from-ingress"
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]

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
      ports {
        port     = "3000"
        protocol = "TCP"
      }
    }
  }
}


