################################################################################
# AI Orchestrator namespace — infrastructure layer
#
# Manages: namespace (PSS), NetworkPolicies, and ResourceQuota.
# Workload manifests (api-gateway, llm-worker, vision-worker, dispatch-worker)
# are owned by Argo CD and live outside this module intentionally — the same
# split used for the portfolio namespace.
################################################################################

resource "kubernetes_namespace" "ai_orchestrator" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name = var.namespace
      # GPU device plugin pods (privileged) may land here; privileged PSS is
      # required for workloads that mount /dev/nvidia* host devices.
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
    })
  }

  lifecycle {
    # Prevent Terraform from destroying the namespace if workloads are present;
    # namespaces are recreated very rarely and destruction would evict live pods.
    prevent_destroy = true
    ignore_changes  = [metadata[0].annotations]
  }
}

# ---------------------------------------------------------------------------
# Network Policies
# ---------------------------------------------------------------------------

# Default-deny all ingress traffic; explicit allow rules below open only the
# minimum required paths.
resource "kubernetes_network_policy_v1" "default_deny_ingress" {
  metadata {
    name      = "default-deny-ingress"
    namespace = kubernetes_namespace.ai_orchestrator.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

# Allow ingress-nginx to reach the api-gateway pod on its HTTP port.
resource "kubernetes_network_policy_v1" "allow_ingress_nginx" {
  metadata {
    name      = "allow-ingress-nginx"
    namespace = kubernetes_namespace.ai_orchestrator.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {
      match_labels = {
        "app.kubernetes.io/name" = "api-gateway"
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
      }

      ports {
        protocol = "TCP"
        port     = tostring(var.api_gateway_port)
      }
    }

    policy_types = ["Ingress"]
  }
}

# Allow intra-namespace traffic so workers can call each other and the
# api-gateway can dispatch to llm-worker / vision-worker / dispatch-worker.
resource "kubernetes_network_policy_v1" "allow_intra_namespace" {
  metadata {
    name      = "allow-intra-namespace"
    namespace = kubernetes_namespace.ai_orchestrator.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {}

    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = var.namespace
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

# Egress: allow DNS resolution via kube-system CoreDNS.
resource "kubernetes_network_policy_v1" "allow_dns_egress" {
  metadata {
    name      = "allow-dns-egress"
    namespace = kubernetes_namespace.ai_orchestrator.metadata[0].name
    labels    = var.tags
  }

  spec {
    pod_selector {}

    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }

      ports {
        protocol = "UDP"
        port     = "53"
      }

      ports {
        protocol = "TCP"
        port     = "53"
      }
    }

    # Allow all egress except what is explicitly blocked; AI workers need to
    # reach model registries, external APIs, and intra-cluster services.
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
          except = [
            "10.96.0.0/12",  # cluster service CIDR — use explicit service rules
          ]
        }
      }
    }

    # Allow all intra-cluster egress (service-to-service, DB, message queues).
    egress {
      to {
        namespace_selector {}
      }
    }

    policy_types = ["Egress"]
  }
}

# ---------------------------------------------------------------------------
# Resource Quota
# ---------------------------------------------------------------------------

resource "kubernetes_resource_quota_v1" "ai_orchestrator" {
  metadata {
    name      = "ai-orchestrator-quota"
    namespace = kubernetes_namespace.ai_orchestrator.metadata[0].name
    labels    = var.tags
  }

  spec {
    hard = {
      pods                    = tostring(var.max_pods)
      persistentvolumeclaims  = tostring(var.max_pvcs)
      "requests.cpu"          = var.cpu_request
      "requests.memory"       = var.memory_request
      "limits.cpu"            = var.cpu_limit
      "limits.memory"         = var.memory_limit
      "requests.nvidia.com/gpu" = tostring(var.gpu_limit)
      "limits.nvidia.com/gpu"   = tostring(var.gpu_limit)
    }
  }
}
