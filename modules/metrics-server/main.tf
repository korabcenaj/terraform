locals {
  metrics_server_labels = {
    "app.kubernetes.io/name"       = "metrics-server"
    "app.kubernetes.io/instance"   = var.release_name
    "app.kubernetes.io/component"  = "metrics"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

resource "kubernetes_service_account_v1" "metrics_server" {
  metadata {
    name      = var.release_name
    namespace = var.namespace
    labels    = local.metrics_server_labels
  }
}

resource "kubernetes_cluster_role_v1" "aggregated_metrics_reader" {
  metadata {
    name = "system:aggregated-metrics-reader"
    labels = {
      "rbac.authorization.k8s.io/aggregate-to-admin" = "true"
      "rbac.authorization.k8s.io/aggregate-to-edit"  = "true"
      "rbac.authorization.k8s.io/aggregate-to-view"  = "true"
    }
  }

  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_v1" "metrics_server" {
  metadata {
    name   = "system:metrics-server"
    labels = local.metrics_server_labels
  }

  rule {
    api_groups = [""]
    resources  = ["nodes/metrics"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "metrics_server_auth_delegator" {
  metadata {
    name   = "metrics-server:system:auth-delegator"
    labels = local.metrics_server_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.metrics_server.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_binding_v1" "metrics_server" {
  metadata {
    name   = "system:metrics-server"
    labels = local.metrics_server_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.metrics_server.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.metrics_server.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_role_binding_v1" "metrics_server_auth_reader" {
  metadata {
    name      = "metrics-server-auth-reader"
    namespace = var.namespace
    labels    = local.metrics_server_labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "extension-apiserver-authentication-reader"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.metrics_server.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_service_v1" "metrics_server" {
  metadata {
    name      = var.release_name
    namespace = var.namespace
    labels    = local.metrics_server_labels
  }

  spec {
    selector = local.metrics_server_labels

    port {
      name        = "https"
      port        = 443
      protocol    = "TCP"
      target_port = "https"
    }
  }
}

resource "kubernetes_deployment_v1" "metrics_server" {
  metadata {
    name      = var.release_name
    namespace = var.namespace
    labels    = local.metrics_server_labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = local.metrics_server_labels
    }

    template {
      metadata {
        labels = local.metrics_server_labels
      }

      spec {
        service_account_name = kubernetes_service_account_v1.metrics_server.metadata[0].name
        priority_class_name  = "system-cluster-critical"

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        security_context {
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }

        container {
          name  = "metrics-server"
          image = var.image

          args = [
            "--cert-dir=/tmp",
            "--secure-port=10250",
            "--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP",
            "--kubelet-use-node-status-port",
            "--metric-resolution=15s",
            "--kubelet-insecure-tls"
          ]

          port {
            name           = "https"
            container_port = 10250
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path   = "/livez"
              port   = "https"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 20
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path   = "/readyz"
              port   = "https"
              scheme = "HTTPS"
            }
            initial_delay_seconds = 20
            period_seconds        = 10
          }

          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 1000

            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            mount_path = "/tmp"
            name       = "tmp-dir"
          }
        }

        volume {
          name = "tmp-dir"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_api_service_v1" "metrics_server" {
  metadata {
    name   = "v1beta1.metrics.k8s.io"
    labels = local.metrics_server_labels
  }

  spec {
    group                    = "metrics.k8s.io"
    group_priority_minimum   = 100
    insecure_skip_tls_verify = true
    service {
      name      = kubernetes_service_v1.metrics_server.metadata[0].name
      namespace = var.namespace
      port      = 443
    }
    version          = "v1beta1"
    version_priority = 100
  }

  depends_on = [kubernetes_deployment_v1.metrics_server]
}
