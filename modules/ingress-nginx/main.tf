resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }
}

resource "helm_release" "ingress_nginx" {
  name       = var.release_name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  set {
    name  = "controller.replicaCount"
    value = tostring(var.replica_count)
  }

  set {
    name  = "controller.service.type"
    value = var.service_type
  }

  # Ensure the IngressClass resource is created and set as default
  set {
    name  = "controller.ingressClassResource.name"
    value = "nginx"
  }

  set {
    name  = "controller.ingressClassResource.default"
    value = "true"
  }

  # Allow snippets for advanced config (required by many charts)
  set {
    name  = "controller.allowSnippetAnnotations"
    value = "true"
  }

  set {
    name  = "controller.metrics.enabled"
    value = tostring(var.enable_metrics)
  }

  # Keep existing pods running during upgrades
  set {
    name  = "controller.updateStrategy.type"
    value = "RollingUpdate"
  }

  wait    = true
  timeout = 300
}
