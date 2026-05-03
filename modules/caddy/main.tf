################################################################################
# Caddy Ingress Controller
# Deploys the official Caddy Ingress Controller via Helm.
# https://github.com/caddyserver/ingress
# IngressClass: caddy
################################################################################

resource "kubernetes_namespace" "caddy" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
    })
  }
}

resource "helm_release" "caddy" {
  name       = var.release_name
  repository = "https://caddyserver.github.io/ingress/"
  chart      = "caddy-ingress-controller"
  version    = var.chart_version
  namespace  = kubernetes_namespace.caddy.metadata[0].name

  # ── IngressClass ──────────────────────────────────────────────────────────
  set {
    name  = "ingressController.config.ingressClass"
    value = var.ingress_class_name
  }

  # Make this the cluster default IngressClass when requested.
  set {
    name  = "ingressController.config.isDefaultIngressClass"
    value = tostring(var.default_ingress_class)
  }

  # ── Service type ──────────────────────────────────────────────────────────
  set {
    name  = "ingressController.service.type"
    value = var.service_type
  }

  # ── Replicas ──────────────────────────────────────────────────────────────
  set {
    name  = "replicaCount"
    value = tostring(var.replica_count)
  }

  # ── TLS / ACME ────────────────────────────────────────────────────────────
  # acme_ca_server can be set to the cluster cert-manager ACME URL or a
  # public CA. Leave empty to disable automatic ACME.
  dynamic "set" {
    for_each = var.acme_ca_server != "" ? [var.acme_ca_server] : []
    content {
      name  = "ingressController.config.acmeCA"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.acme_email != "" ? [var.acme_email] : []
    content {
      name  = "ingressController.config.email"
      value = set.value
    }
  }

  # ── Metrics ───────────────────────────────────────────────────────────────
  set {
    name  = "ingressController.config.metrics"
    value = tostring(var.enable_metrics)
  }

  # ── Debug / log level ─────────────────────────────────────────────────────
  set {
    name  = "ingressController.config.debug"
    value = tostring(var.debug)
  }

  # ── On-demand TLS ─────────────────────────────────────────────────────────
  set {
    name  = "ingressController.config.onDemandTLS"
    value = tostring(var.on_demand_tls)
  }

  wait    = true
  timeout = 300

  depends_on = [kubernetes_namespace.caddy]
}
