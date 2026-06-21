resource "kubernetes_namespace" "falco" {
  metadata {
    name = "falco"
    labels = merge(var.tags, {
      name                                 = "falco"
      "pod-security.kubernetes.io/enforce" = "privileged"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "falco" {
  name       = var.release_name
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  version    = var.chart_version
  namespace  = kubernetes_namespace.falco.metadata[0].name

  set {
    name  = "tty"
    value = "true"
  }

  # Kyverno compliance: resource limits and non-root user
  set {
    name  = "falco.jsonOutput"
    value = "true"
  }

  set {
    name  = "resources.limits.cpu"
    value = "500m"
  }

  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  # Falcoctl sidecar resource limits (Kyverno require-resource-limits)
  set {
    name  = "falcoctl.artifact.follow.resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "falcoctl.artifact.follow.resources.limits.memory"
    value = "128Mi"
  }

  set {
    name  = "falcoctl.artifact.follow.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "falcoctl.artifact.follow.resources.requests.memory"
    value = "64Mi"
  }

  set {
    name  = "falcoctl.artifact.install.resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "falcoctl.artifact.install.resources.limits.memory"
    value = "128Mi"
  }

  set {
    name  = "falcoctl.artifact.install.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "falcoctl.artifact.install.resources.requests.memory"
    value = "64Mi"
  }

  # Falco needs root; set explicitly for Kyverno visibility
  set {
    name  = "containerSecurityContext.runAsNonRoot"
    value = "false"
  }

  # Outbound HTTPS interception fix: the cilium module now sets
  #   l7Proxy = false
  #   socketLB.hostNamespaceOnly = true
  # which prevents Cilium's eBPF programs from redirecting host-namespace
  # port-443 traffic to Traefik's service backend.  Falco can now safely
  # schedule on control-plane nodes.
  # (Previously we set tolerations=[] as a workaround.)

  wait    = false
  timeout = 600
}
