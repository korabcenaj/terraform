resource "helm_release" "rancher_turtles" {
  name       = var.release_name
  repository = "https://rancher.github.io/turtles"
  chart      = "rancher-turtles"
  version    = var.chart_version
  namespace  = "cattle-turtles-system"

  set {
    name  = "features.no-cert-manager.enabled"
    value = "true"
  }

  set {
    name  = "global.cattle.systemDefaultRegistry"
    value = ""
  }

  set {
    name  = "priorityClassName"
    value = "rancher-critical"
  }

  wait    = true
  timeout = 600
}
