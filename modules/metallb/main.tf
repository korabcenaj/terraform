resource "kubernetes_namespace" "metallb" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }
}

resource "helm_release" "metallb" {
  name       = var.release_name
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = var.chart_version
  namespace  = kubernetes_namespace.metallb.metadata[0].name

  wait    = true
  timeout = 300

  # CRD install hook
  set {
    name  = "crds.enabled"
    value = "true"
  }

  dynamic "set" {
    for_each = var.extra_values
    content {
      name  = set.key
      value = set.value
    }
  }
}

# IPAddressPool for LAN services
resource "kubernetes_manifest" "ip_address_pool" {
  count = var.ip_pool_addresses != "" ? 1 : 0

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = var.ip_pool_name
      namespace = kubernetes_namespace.metallb.metadata[0].name
    }
    spec = {
      addresses = [var.ip_pool_addresses]
    }
  }

  depends_on = [helm_release.metallb]
}

# L2Advertisement to announce pool over LAN
resource "kubernetes_manifest" "l2_advertisement" {
  count = var.ip_pool_addresses != "" ? 1 : 0

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = var.ip_pool_name
      namespace = kubernetes_namespace.metallb.metadata[0].name
    }
    spec = {
      ipAddressPools = [var.ip_pool_name]
    }
  }

  depends_on = [kubernetes_manifest.ip_address_pool]
}
