# Website Tracker Operator — namespace only
# The Helm release is managed externally (installed from Harbor registry).
# Terraform manages only the namespace to avoid chart path dependency.

resource "kubernetes_namespace" "website_tracker" {
  metadata {
    name = "website-tracker-system"
    labels = merge(var.tags, {
      name = "website-tracker-system"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
