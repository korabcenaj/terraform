# Tekton Pipelines - managed by Argo CD
# This module creates only the namespace
# The actual deployments are managed via Argo CD Application manifests

resource "kubernetes_namespace" "tekton_pipelines" {
  metadata {
    name = "tekton-pipelines"
    labels = merge(var.tags, {
      name = "tekton-pipelines"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_namespace" "tekton_pipelines_resolvers" {
  metadata {
    name = "tekton-pipelines-resolvers"
    labels = merge(var.tags, {
      name = "tekton-pipelines-resolvers"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
