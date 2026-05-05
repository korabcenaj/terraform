terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

variable "release_name" {
  type    = string
  default = "skills-dashboard"
}

variable "namespace" {
  type    = string
  default = "default"
}

variable "image_repository" {
  type    = string
  default = "192.168.1.13:30002/library/skills-dashboard"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "replicas" {
  type    = number
  default = 2
}

variable "host" {
  type        = string
  description = "Ingress hostname for the dashboard"
}

variable "ingress_class_name" {
  type    = string
  default = "nginx"
}

variable "resource_limits_cpu" {
  type    = string
  default = "500m"
}

variable "resource_limits_memory" {
  type    = string
  default = "512Mi"
}

variable "resource_requests_cpu" {
  type    = string
  default = "100m"
}

variable "resource_requests_memory" {
  type    = string
  default = "128Mi"
}

variable "enable_ingress" {
  type    = bool
  default = true
}

variable "tls_enabled" {
  type    = bool
  default = false
}

variable "annotations" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Namespace
resource "kubernetes_namespace_v1" "dashboard" {
  metadata {
    name = var.namespace
    labels = merge(
      var.tags,
      {
        "app.kubernetes.io/name" = "skills-dashboard"
      }
    )
  }
}

# ServiceAccount with cluster reader permissions
resource "kubernetes_service_account_v1" "dashboard" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace_v1.dashboard.metadata[0].name
    labels = merge(
      var.tags,
      {
        "app.kubernetes.io/name"     = "skills-dashboard"
        "app.kubernetes.io/instance" = var.release_name
      }
    )
  }
}

# ClusterRole for reading cluster state
resource "kubernetes_cluster_role_v1" "dashboard" {
  metadata {
    name = var.release_name
    labels = merge(
      var.tags,
      {
        "app.kubernetes.io/name"     = "skills-dashboard"
        "app.kubernetes.io/instance" = var.release_name
      }
    )
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "services", "endpoints"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list"]
  }
}

# ClusterRoleBinding
resource "kubernetes_cluster_role_binding_v1" "dashboard" {
  metadata {
    name = var.release_name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.dashboard.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.dashboard.metadata[0].name
    namespace = kubernetes_namespace_v1.dashboard.metadata[0].name
  }
}

# Deployment
resource "kubernetes_deployment_v1" "dashboard" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace_v1.dashboard.metadata[0].name
    labels = merge(
      var.tags,
      {
        "app.kubernetes.io/name"       = "skills-dashboard"
        "app.kubernetes.io/instance"   = var.release_name
        "app.kubernetes.io/component"  = "dashboard"
      }
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name"     = "skills-dashboard"
        "app.kubernetes.io/instance" = var.release_name
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"     = "skills-dashboard"
          "app.kubernetes.io/instance" = var.release_name
        }
        annotations = merge(
          var.annotations,
          {
            "prometheus.io/scrape" = "true"
            "prometheus.io/port"   = "3000"
          }
        )
      }

      spec {
        service_account_name = kubernetes_service_account_v1.dashboard.metadata[0].name

        container {
          name  = "dashboard"
          image = "${var.image_repository}:${var.image_tag}"

          image_pull_policy = "Always"

          port {
            name           = "http"
            container_port = 3000
            protocol       = "TCP"
          }

          env {
            name  = "PORT"
            value = "3000"
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          resources {
            limits = {
              cpu    = var.resource_limits_cpu
              memory = var.resource_limits_memory
            }
            requests = {
              cpu    = var.resource_requests_cpu
              memory = var.resource_requests_memory
            }
          }

          liveness_probe {
            http_get {
              path   = "/health"
              port   = 3000
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path   = "/health"
              port   = 3000
              scheme = "HTTP"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 2
            failure_threshold     = 2
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
            run_as_non_root            = true
            run_as_user                = 1000
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        security_context {
          fs_group = 1000
        }

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["skills-dashboard"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_cluster_role_binding_v1.dashboard]
}

# Service
resource "kubernetes_service_v1" "dashboard" {
  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace_v1.dashboard.metadata[0].name
    labels = merge(
      var.tags,
      {
        "app.kubernetes.io/name"     = "skills-dashboard"
        "app.kubernetes.io/instance" = var.release_name
      }
    )
  }

  spec {
    type = "ClusterIP"

    port {
      port        = 80
      target_port = 3000
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      "app.kubernetes.io/name"     = "skills-dashboard"
      "app.kubernetes.io/instance" = var.release_name
    }
  }
}

# Ingress
resource "kubernetes_ingress_v1" "dashboard" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = var.release_name
    namespace = kubernetes_namespace_v1.dashboard.metadata[0].name
    labels = merge(
      var.tags,
      {
        "app.kubernetes.io/name"     = "skills-dashboard"
        "app.kubernetes.io/instance" = var.release_name
      }
    )
    annotations = merge(
      var.annotations,
      {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      }
    )
  }

  spec {
    ingress_class_name = var.ingress_class_name

    dynamic "tls" {
      for_each = var.tls_enabled ? [1] : []
      content {
        hosts       = [var.host]
        secret_name = "${var.release_name}-tls"
      }
    }

    rule {
      host = var.host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.dashboard.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
