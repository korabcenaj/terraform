resource "helm_release" "fleet" {
  name       = var.release_name
  repository = "https://rancher.github.io/fleet-helm-charts/"
  chart      = "fleet"
  version    = var.chart_version
  namespace  = "cattle-fleet-system"

  set {
    name  = "apiServerURL"
    value = var.rancher_url
  }

  set {
    name  = "apiServerCA"
    value = ""
  }

  set {
    name  = "agentTLSMode"
    value = "strict"
  }

  set {
    name  = "gitops.enabled"
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

  # ---- Resource limits ----
  set {
    name  = "resources.requests.cpu"
    value = "25m"
  }
  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "resources.limits.cpu"
    value = "250m"
  }
  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  wait    = true
  timeout = 300
}

resource "helm_release" "fleet_crd" {
  name       = "${var.release_name}-crd"
  repository = "https://rancher.github.io/fleet-helm-charts/"
  chart      = "fleet-crd"
  version    = var.fleet_crd_chart_version
  namespace  = "cattle-fleet-system"

  wait    = true
  timeout = 300
}
