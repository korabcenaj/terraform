resource "kubernetes_namespace" "this" {
  metadata {
    name = var.name
    labels = merge(var.tags, {
      name                                 = var.name
      "pod-security.kubernetes.io/enforce" = var.pod_security_enforce
      "pod-security.kubernetes.io/audit"   = var.pod_security_audit
      "pod-security.kubernetes.io/warn"    = var.pod_security_warn
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_resource_quota" "this" {
  metadata {
    name      = "${var.name}-quota"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = var.tags
  }

  spec {
    hard = {
      pods              = var.pod_limit
      "requests.cpu"    = var.cpu_request_quota
      "requests.memory" = var.memory_request_quota
      "limits.cpu"      = var.cpu_limit_quota
      "limits.memory"   = var.memory_limit_quota
    }
  }
}

resource "kubernetes_limit_range" "this" {
  metadata {
    name      = "${var.name}-limits"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = var.tags
  }

  spec {
    limit {
      type = "Container"
      default = {
        cpu    = var.default_cpu_limit
        memory = var.default_memory_limit
      }
      default_request = {
        cpu    = var.default_cpu_request
        memory = var.default_memory_request
      }
    }
  }
}

resource "kubernetes_network_policy" "default_deny" {
  count = var.create_default_deny ? 1 : 0

  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace.this.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}
