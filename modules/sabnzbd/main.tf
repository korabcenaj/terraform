# Sabnzbd Usenet downloader - managed by Argo CD
# This module creates the namespace; the deployment is managed via Argo CD

resource "kubernetes_namespace" "sabnzbd" {
  metadata {
    name = "sabnzbd"
    labels = merge(var.tags, {
      name = "sabnzbd"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
