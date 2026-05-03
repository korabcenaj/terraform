resource "kubernetes_namespace" "falco" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }
}

resource "helm_release" "falco" {
  name       = var.release_name
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  version    = var.chart_version
  namespace  = kubernetes_namespace.falco.metadata[0].name

  wait    = true
  timeout = 300

  # Use eBPF probe for modern kernels (no kernel module required)
  set {
    name  = "driver.kind"
    value = var.driver_kind
  }

  set {
    name  = "driver.ebpf.leastPrivileged"
    value = "true"
  }

  # Falcosidekick integration for alert forwarding
  set {
    name  = "falcosidekick.enabled"
    value = tostring(var.enable_falcosidekick)
  }

  # JSON output for log aggregation
  set {
    name  = "falco.jsonOutput"
    value = "true"
  }

  set {
    name  = "falco.jsonIncludeOutputProperty"
    value = "true"
  }

  # Metrics endpoint for Prometheus scraping
  set {
    name  = "falco.metricsSdEnabled"
    value = tostring(var.enable_metrics)
  }

  # Log level
  set {
    name  = "falco.logLevel"
    value = var.log_level
  }

  dynamic "set" {
    for_each = var.extra_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
