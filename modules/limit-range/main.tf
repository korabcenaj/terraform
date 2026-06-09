# ===========================================================================
# LimitRange — Default CPU/Memory for all containers
#
# Applied per-namespace.  Any container without explicit resources.requests
# or resources.limits gets these defaults.  Prevents unbounded pods from
# starving the cluster.
# ===========================================================================

resource "kubernetes_limit_range" "defaults" {
  metadata {
    name      = "namespace-limits"
    namespace = var.namespace
    labels    = var.tags
  }

  spec {
    limit {
      type = "Container"

      # ---- Default requests (applied when container has none) ----
      default_request = {
        cpu    = var.default_cpu_request
        memory = var.default_memory_request
      }

      # ---- Default limits (applied when container has none) ----
      default = {
        cpu    = var.default_cpu_limit
        memory = var.default_memory_limit
      }

      # ---- Minimum (prevents setting trivially low values) ----
      min = {
        cpu    = "10m"
        memory = "32Mi"
      }

      # ---- Maximum (prevents a single container from taking the node) ----
      max = {
        cpu    = var.max_cpu_limit
        memory = var.max_memory_limit
      }
    }
  }
}
