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
  name       = var.release_name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  # Increase timeout — this chart installs many CRDs and resources
  wait    = true
  timeout = 600

  # Install/upgrade CRDs
  set {
    name  = "crds.enabled"
    value = "true"
  }

  # ----- Grafana -----
  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = var.grafana_storage_class
  }

  set {
    name  = "grafana.persistence.size"
    value = var.grafana_storage_size
  }

  # Ingress handled separately (via existing monitoring module)
  set {
    name  = "grafana.ingress.enabled"
    value = "false"
  }

  # ----- Prometheus -----
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.prometheus_storage_class
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }

  # Ingress handled separately (via existing monitoring module)
  set {
    name  = "prometheus.ingress.enabled"
    value = "false"
  }

  # ----- Alertmanager -----
  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  # ----- Node Exporter -----
  set {
    name  = "nodeExporter.enabled"
    value = "true"
  }

  # ----- kube-state-metrics -----
  set {
    name  = "kubeStateMetrics.enabled"
    value = "true"
  }
}
