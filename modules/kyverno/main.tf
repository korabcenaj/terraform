resource "kubernetes_namespace" "kyverno" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name = var.namespace
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "helm_release" "kyverno" {
  name       = var.release_name
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = var.chart_version
  namespace  = kubernetes_namespace.kyverno.metadata[0].name

  # Single-replica per component — appropriate for a homelab single-node cluster
  set {
    name  = "admissionController.replicas"
    value = "1"
  }

  set {
    name  = "backgroundController.replicas"
    value = "1"
  }

  set {
    name  = "cleanupController.replicas"
    value = "1"
  }

  set {
    name  = "reportsController.replicas"
    value = "1"
  }

  wait    = true
  timeout = 600
}

# ---------------------------------------------------------------------------
# ClusterPolicies
# NOTE: CRDs are installed by the Helm chart above. These resources require
# the CRDs to exist at plan time. Set enable_policies = true only after the
# Helm chart has been applied and Kyverno CRDs are registered in the cluster.
# ---------------------------------------------------------------------------

# Policy: Disallow the ':latest' image tag
resource "kubernetes_manifest" "policy_disallow_latest_tag" {
  count = var.enable_policies ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-latest-tag"
      annotations = {
        "policies.kyverno.io/title"       = "Disallow Latest Tag"
        "policies.kyverno.io/category"    = "Best Practices"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "The ':latest' tag is mutable and can lead to unexpected errors. Require a specific, immutable image tag."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode
      background              = true
      rules = [
        {
          name = "require-image-tag"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Pod"]
                }
              }
            ]
          }
          validate = {
            message = "An image tag is required and ':latest' is not permitted. Use a specific version tag."
            pattern = {
              spec = {
                containers = [
                  {
                    image = "!*:latest"
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.kyverno]
}

# Policy: Require CPU and memory limits on all containers
resource "kubernetes_manifest" "policy_require_limits" {
  count = var.enable_policies ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "require-resource-limits"
      annotations = {
        "policies.kyverno.io/title"       = "Require Resource Limits"
        "policies.kyverno.io/category"    = "Best Practices"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "All containers must define CPU and memory limits to prevent resource exhaustion."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode
      background              = true
      rules = [
        {
          name = "require-limits"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Pod"]
                }
              }
            ]
          }
          validate = {
            message = "CPU and memory limits are required for all containers."
            pattern = {
              spec = {
                containers = [
                  {
                    resources = {
                      limits = {
                        memory = "?*"
                        cpu    = "?*"
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.kyverno]
}

# Policy: Block privileged containers
resource "kubernetes_manifest" "policy_disallow_privileged" {
  count = var.enable_policies ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "disallow-privileged-containers"
      annotations = {
        "policies.kyverno.io/title"       = "Disallow Privileged Containers"
        "policies.kyverno.io/category"    = "Pod Security Standards (Baseline)"
        "policies.kyverno.io/severity"    = "high"
        "policies.kyverno.io/description" = "Privileged mode disables most security mechanisms. Containers must not run in privileged mode."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode
      background              = true
      rules = [
        {
          name = "disallow-privileged-containers"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Pod"]
                }
              }
            ]
          }
          validate = {
            message = "Privileged containers are not permitted."
            pattern = {
              spec = {
                "=(containers)" = [
                  {
                    "=(securityContext)" = {
                      "=(privileged)" = "false"
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.kyverno]
}

# Policy: Require non-root user in containers
resource "kubernetes_manifest" "policy_require_non_root" {
  count = var.enable_policies ? 1 : 0

  manifest = {
    apiVersion = "kyverno.io/v1"
    kind       = "ClusterPolicy"
    metadata = {
      name = "require-run-as-non-root"
      annotations = {
        "policies.kyverno.io/title"       = "Require Non-Root User"
        "policies.kyverno.io/category"    = "Pod Security Standards (Restricted)"
        "policies.kyverno.io/severity"    = "medium"
        "policies.kyverno.io/description" = "Containers must not run as root. Set runAsNonRoot: true in the security context."
      }
    }
    spec = {
      validationFailureAction = var.enforcement_mode
      background              = true
      rules = [
        {
          name = "check-run-as-non-root"
          match = {
            any = [
              {
                resources = {
                  kinds = ["Pod"]
                }
              }
            ]
          }
          validate = {
            message = "Containers must run as a non-root user. Set securityContext.runAsNonRoot: true."
            pattern = {
              spec = {
                "=(securityContext)" = {
                  "=(runAsNonRoot)" = "true"
                }
                containers = [
                  {
                    "=(securityContext)" = {
                      "=(runAsNonRoot)" = "true"
                    }
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }

  depends_on = [helm_release.kyverno]
}
