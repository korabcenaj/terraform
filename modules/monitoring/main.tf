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
    name      = "prometheus"
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
  }
}

# Example: Reference existing Grafana installation
data "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = data.kubernetes_namespace.monitoring.metadata[0].name
  }
}
