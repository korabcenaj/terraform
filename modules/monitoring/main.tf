# Monitoring stack — deploys kube-prometheus-stack via Helm.
# Manages the monitoring namespace, Prometheus, Grafana, Alertmanager, node-exporters,
# and the Grafana ingress with network policies.

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = var.kps_release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kps_chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  timeout    = var.kps_timeout

  # Prometheus
  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = var.prometheus_cpu_request
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = var.prometheus_memory_request
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.cpu"
    value = var.prometheus_cpu_limit
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = var.prometheus_memory_limit
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Grafana
  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }

  # Alertmanager
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  # Node exporter and kube-state-metrics
  set {
    name  = "defaultRules.create"
    value = "true"
  }

  set {
    name  = "nodeExporter.enabled"
    value = "true"
  }

  set {
    name  = "kube-state-metrics.enabled"
    value = "true"
  }
}

# Reference the Grafana service created by the Helm release
data "kubernetes_service" "grafana" {
  metadata {
    name      = var.grafana_service_name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  depends_on = [helm_release.kube_prometheus_stack]
}

# Ingress for Grafana
resource "kubernetes_ingress_v1" "grafana" {
  metadata {
    name      = "monitoring-grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
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
    namespace = kubernetes_namespace.monitoring.metadata[0].name
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
    namespace = kubernetes_namespace.monitoring.metadata[0].name
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


