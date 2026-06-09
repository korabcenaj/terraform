resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb-system"
    labels = merge(var.tags, {
      name                                 = "metallb-system"
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "metallb" {
  name       = var.release_name
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = var.chart_version
  namespace  = kubernetes_namespace.metallb.metadata[0].name

  # Increased from 300s — the cluster API server can be under contention
  # when multiple Helm charts deploy simultaneously.
  wait    = true
  timeout = 600

  # Resource limits required by the compute-quota ResourceQuota in this namespace.
  # Without these, pods fail with: "failed quota: compute-quota: must specify limits/requests"
  set {
    name  = "controller.resources.requests.cpu"
    value = "10m"
  }
  set {
    name  = "controller.resources.requests.memory"
    value = "32Mi"
  }
  set {
    name  = "controller.resources.limits.cpu"
    value = "100m"
  }
  set {
    name  = "controller.resources.limits.memory"
    value = "128Mi"
  }
  set {
    name  = "speaker.resources.requests.cpu"
    value = "10m"
  }
  set {
    name  = "speaker.resources.requests.memory"
    value = "32Mi"
  }
  set {
    name  = "speaker.resources.limits.cpu"
    value = "100m"
  }
  set {
    name  = "speaker.resources.limits.memory"
    value = "128Mi"
  }

  # FRR sub-containers also need resources for the quota
  set {
    name  = "speaker.frr.resources.requests.cpu"
    value = "10m"
  }
  set {
    name  = "speaker.frr.resources.requests.memory"
    value = "32Mi"
  }
  set {
    name  = "speaker.frr.resources.limits.cpu"
    value = "100m"
  }
  set {
    name  = "speaker.frr.resources.limits.memory"
    value = "128Mi"
  }

  # Probes: default initialDelay=10s + timeout=1s is too tight for the
  # controller's metrics server startup, causing CrashLoopBackOff (exit 137).
  set {
    name  = "controller.livenessProbe.initialDelaySeconds"
    value = "30"
  }
  set {
    name  = "controller.livenessProbe.timeoutSeconds"
    value = "5"
  }
  set {
    name  = "controller.readinessProbe.initialDelaySeconds"
    value = "30"
  }
  set {
    name  = "controller.readinessProbe.timeoutSeconds"
    value = "5"
  }
}

resource "kubernetes_manifest" "ip_address_pool" {
  field_manager {
    force_conflicts = true
  }

  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = var.address_pool_name
      namespace = kubernetes_namespace.metallb.metadata[0].name
    }
    spec = {
      addresses = [var.address_range]
    }
  }

  depends_on = [helm_release.metallb]
}

resource "kubernetes_manifest" "l2_advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = var.l2_advertisement_name
      namespace = kubernetes_namespace.metallb.metadata[0].name
    }
    spec = {
      ipAddressPools = [var.address_pool_name]
    }
  }

  depends_on = [kubernetes_manifest.ip_address_pool]
}
