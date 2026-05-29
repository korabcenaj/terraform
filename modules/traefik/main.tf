resource "kubernetes_namespace" "traefik" {
  metadata {
    name = "traefik"
    labels = merge(var.tags, {
      name                                 = "traefik"
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "traefik" {
  name       = var.release_name
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = var.chart_version
  namespace  = kubernetes_namespace.traefik.metadata[0].name

  set {
    name  = "deployment.replicas"
    value = tostring(var.replicas)
  }

  set {
    name  = "service.type"
    value = var.service_type
  }

  dynamic "set" {
    for_each = var.service_type == "LoadBalancer" && var.load_balancer_ip != "" ? [1] : []
    content {
      name  = "service.spec.loadBalancerIP"
      value = var.load_balancer_ip
    }
  }

  wait    = true
  timeout = 600
}
