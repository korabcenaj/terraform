# Argo Workflows - managed by Argo CD, this module creates only the namespace
# The actual deployments are managed via Argo CD Application manifests

resource "kubernetes_namespace" "argo" {
  metadata {
    name = "argo"
    labels = merge(var.tags, {
      name = "argo"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_namespace" "argo_events" {
  count = var.enable_argo_events ? 1 : 0

  metadata {
    name = "argo-events"
    labels = merge(var.tags, {
      name = "argo-events"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_namespace" "argo_rollouts" {
  count = var.enable_argo_rollouts ? 1 : 0

  metadata {
    name = "argo-rollouts"
    labels = merge(var.tags, {
      name = "argo-rollouts"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
