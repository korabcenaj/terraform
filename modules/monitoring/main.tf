# Monitoring stack is already deployed via Helm charts in the cluster
# This module serves as a placeholder and documentation for monitoring configuration

# In production, we would manage Prometheus, Grafana, Alertmanager here
# For now, we reference the existing monitoring namespace

data "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Example: Reference existing Prometheus installation
data "kubernetes_service" "prometheus" {
  metadata {
    name      = var.prometheus_service_name
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
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
    name      = "grafana"
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer" = "local-lan-ca"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.grafana_host]
      secret_name = "grafana-tls"
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

# Ingress for Prometheus
resource "kubernetes_ingress_v1" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer" = "local-lan-ca"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.prometheus_host]
      secret_name = "prometheus-tls"
    }

    rule {
      host = var.prometheus_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.prometheus_service_name
              port {
                number = var.prometheus_service_port
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

# Allow ingress-nginx to reach Grafana and Prometheus
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
            "kubernetes.io/metadata.name" = "ingress-nginx"
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
      ports {
        port     = "9090"
        protocol = "TCP"
      }
      ports {
        port     = "9093"
        protocol = "TCP"
      }
    }
  }
}

# Allow Prometheus to scrape all namespaces (metrics egress)
resource "kubernetes_network_policy" "monitoring_allow_scrape_egress" {
  metadata {
    name      = "allow-scrape-egress"
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {
      match_labels = {
        app = "prometheus"
      }
    }
    policy_types = ["Egress"]

    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        port     = "9100"
        protocol = "TCP"
      }
      ports {
        port     = "10250"
        protocol = "TCP"
      }
      ports {
        port     = "10255"
        protocol = "TCP"
      }
      ports {
        port     = "8080"
        protocol = "TCP"
      }
    }

    # DNS
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
  }
}
