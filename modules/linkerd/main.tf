# Linkerd is installed via CLI (`linkerd install`), not Helm.
# This module only creates the namespace and documents the expected state.
# The actual control plane is managed by the linkerd CLI.
# To re-install or upgrade, use: linkerd install | kubectl apply -f -

resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "linkerd"
    labels = merge(var.tags, {
      name                                     = "linkerd"
      "linkerd.io/control-plane-ns"            = "linkerd"
      "linkerd.io/is-control-plane"            = "true"
      "config.linkerd.io/admission-webhooks"   = "disabled"
      "pod-security.kubernetes.io/enforce"     = "privileged"
    })
    annotations = {
      "linkerd.io/inject" = "disabled"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_namespace" "linkerd_viz" {
  count = var.enable_linkerd_viz ? 1 : 0

  metadata {
    name = "linkerd-viz"
    labels = merge(var.tags, {
      name = "linkerd-viz"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
