################################################################################
# Directly Managed Resources
# Existing cluster deployments imported into Terraform (non-Helm, non-module)
# These were created outside Terraform and are now brought under management.
#
# ─── Explicitly NOT imported (separate GitOps tooling) ───
#
#   flux-system          Bootstrapped Flux CD controllers — self-managing.
#                        Managed via `flux bootstrap` and GitRepository/Kustomization
#                        CRDs.  Importing into Terraform would create conflicting
#                        reconciliation loops.
#
#   gitea-runner-flux-trigger  ClusterRole + ClusterRoleBinding managed by Flux.
#
#   grafana-alloy        Abandoned/incomplete deployment (0/1 ready, 22d old).
#                        Left unmanaged pending decision to complete or remove.
#
#   cilium-secrets       Empty namespace — no resources to import.
################################################################################

# ===========================================================================
# MinIO - in-cluster S3-compatible object storage (plain k8s, NOT Helm)
# Used by Velero for backups. Data PVC: minio-data-longhorn
# ===========================================================================

resource "kubernetes_namespace" "minio_direct" {
  count = var.enable_minio_direct ? 1 : 0
  metadata {
    name = "minio"
    labels = merge(var.tags, {
      name                                 = "minio"
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_secret_v1" "minio_credentials" {
  count = var.enable_minio_direct ? 1 : 0
  metadata {
    name      = "minio-credentials"
    namespace = "minio"
  }
  type = "Opaque"
  lifecycle { ignore_changes = [data, metadata[0].annotations] }
}

resource "kubernetes_persistent_volume_claim_v1" "minio_data" {
  count = var.enable_minio_direct ? 1 : 0
  metadata {
    name      = "minio-data-longhorn"
    namespace = "minio"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_deployment_v1" "minio" {
  count = var.enable_minio_direct ? 1 : 0
  metadata {
    name      = "minio"
    namespace = "minio"
    labels = merge(var.tags, {
      app                              = "minio"
      "backup.kubernetes.io/component" = "s3-target"
    })
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "minio" }
    }
    strategy {
      type = "Recreate"
    }
    template {
      metadata {
        labels = { app = "minio" }
      }
      spec {
        automount_service_account_token = false
        node_selector = {
          "kubernetes.io/hostname" = "k8s-master"
        }
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        toleration {
          key      = "node-role.kubernetes.io/master"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        container {
          name  = "minio"
          image = "quay.io/minio/minio:latest"
          args  = ["server", "/data", "--console-address", ":9001"]

          port {
            name           = "api"
            container_port = 9000
            protocol       = "TCP"
          }
          port {
            name           = "console"
            container_port = 9001
            protocol       = "TCP"
          }

          env {
            name = "MINIO_ROOT_USER"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "root-user"
              }
            }
          }
          env {
            name = "MINIO_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "minio-credentials"
                key  = "root-password"
              }
            }
          }
          env {
            name  = "MINIO_BROWSER"
            value = "on"
          }
          env {
            name  = "MINIO_STORAGE_CLASS_STANDARD"
            value = "EC:0"
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/minio/health/live"
              port = 9000
            }
            initial_delay_seconds = 30
            period_seconds        = 20
          }
          readiness_probe {
            http_get {
              path = "/minio/health/ready"
              port = 9000
            }
            initial_delay_seconds = 20
            period_seconds        = 10
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = "minio-data-longhorn"
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].template[0].metadata[0].annotations,
      spec[0].template[0].spec[0].container[0].image,
    ]
  }
}

resource "kubernetes_service_v1" "minio" {
  count = var.enable_minio_direct ? 1 : 0
  metadata {
    name      = "minio"
    namespace = "minio"
    labels    = merge(var.tags, { app = "minio" })
  }
  spec {
    type     = "ClusterIP"
    selector = { app = "minio" }
    port {
      name        = "api"
      port        = 9000
      target_port = 9000
      protocol    = "TCP"
    }
    port {
      name        = "console"
      port        = 9001
      target_port = 9001
      protocol    = "TCP"
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].cluster_ip,
      spec[0].cluster_ips,
    ]
  }
}

resource "kubernetes_service_v1" "minio_external" {
  count = var.enable_minio_direct ? 1 : 0
  metadata {
    name      = "minio-external"
    namespace = "minio"
    labels    = merge(var.tags, { app = "minio" })
  }
  spec {
    type     = "LoadBalancer"
    selector = { app = "minio" }
    port {
      name        = "api"
      port        = 9000
      target_port = 9000
      protocol    = "TCP"
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].cluster_ip,
      spec[0].cluster_ips,
    ]
  }
}


# ===========================================================================
# Gitea Actions Runner - CI/CD runner for Gitea
# ===========================================================================

resource "kubernetes_namespace" "gitea_runner" {
  count = var.enable_gitea_runner ? 1 : 0
  metadata {
    name = "gitea-runner"
    labels = merge(var.tags, {
      name                                 = "gitea-runner"
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_config_map_v1" "gitea_runner_config" {
  count = var.enable_gitea_runner ? 1 : 0
  metadata {
    name      = "gitea-runner-config"
    namespace = "gitea-runner"
  }
  lifecycle { ignore_changes = [data, metadata[0].annotations] }
}

resource "kubernetes_secret_v1" "gitea_runner_token" {
  count = var.enable_gitea_runner ? 1 : 0
  metadata {
    name      = "gitea-runner-token"
    namespace = "gitea-runner"
  }
  type = "Opaque"
  lifecycle { ignore_changes = [data, metadata[0].annotations] }
}

resource "kubernetes_persistent_volume_claim_v1" "gitea_runner_data" {
  count = var.enable_gitea_runner ? 1 : 0
  metadata {
    name      = "gitea-runner-data-longhorn"
    namespace = "gitea-runner"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_cluster_role_v1" "gitea_runner_cr" {
  count    = var.enable_gitea_runner ? 1 : 0
  metadata { name = "gitea-runner" }
  lifecycle { ignore_changes = [metadata[0].annotations, rule] }
}

resource "kubernetes_deployment_v1" "gitea_runner" {
  count = var.enable_gitea_runner ? 1 : 0
  metadata {
    name      = "gitea-runner"
    namespace = "gitea-runner"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "gitea-runner" }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }
    template {
      metadata {
        labels = { app = "gitea-runner" }
      }
      spec {
        container {
          name  = "dind"
          image = "docker:27-dind"
          security_context {
            privileged = true
          }
          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "2000m"
              memory = "2Gi"
            }
          }
          volume_mount {
            name       = "docker-storage"
            mount_path = "/var/lib/docker"
          }
        }
        container {
          name  = "runner"
          image = "gitea/act_runner:0.2.11"
          resources {
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
            }
          }
          volume_mount {
            name       = "runner-data"
            mount_path = "/data"
          }
          volume_mount {
            name       = "runner-config"
            mount_path = "/etc/act_runner"
          }
          env {
            name  = "GITEA_INSTANCE_URL"
            value = "http://gitea-http.git.svc.cluster.local:3000"
          }
          env {
            name = "GITEA_RUNNER_REGISTRATION_TOKEN"
            value_from {
              secret_key_ref {
                name = "gitea-runner-token"
                key  = "token"
              }
            }
          }
          env {
            name  = "DOCKER_HOST"
            value = "tcp://localhost:2375"
          }
        }
        volume {
          name = "runner-data"
          empty_dir {
            size_limit = "1Gi"
          }
        }
        volume {
          name = "runner-config"
          config_map {
            name = "gitea-runner-config"
          }
        }
        volume {
          name = "docker-storage"
          empty_dir {
            size_limit = "10Gi"
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].template[0].metadata[0].annotations,
    ]
  }
}


# ===========================================================================
# qBittorrent - Torrent client
# ===========================================================================

resource "kubernetes_namespace" "qbittorrent" {
  count = var.enable_qbittorrent ? 1 : 0
  metadata {
    name = "qbittorrent"
    labels = merge(var.tags, {
      name                                 = "qbittorrent"
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_persistent_volume_claim_v1" "qbittorrent_config" {
  count = var.enable_qbittorrent ? 1 : 0
  metadata {
    name      = "qbittorrent-config-pvc"
    namespace = "qbittorrent"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "longhorn"
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_deployment_v1" "qbittorrent" {
  count = var.enable_qbittorrent ? 1 : 0
  metadata {
    name      = "qbittorrent"
    namespace = "qbittorrent"
    labels    = merge(var.tags, { app = "qbittorrent", environment = "production" })
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "qbittorrent" }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }
    template {
      metadata {
        labels = { app = "qbittorrent" }
      }
      spec {
        automount_service_account_token = false
        node_selector = {
          "kubernetes.io/hostname" = "k8s-master"
        }
        security_context {
          seccomp_profile {
            type = "RuntimeDefault"
          }
        }
        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }
        dns_config {
          option {
            name  = "ndots"
            value = "1"
          }
        }
        container {
          name  = "qbittorrent"
          image = "linuxserver/qbittorrent:5.1.4"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }
          port {
            name           = "torrent"
            container_port = 6881
            protocol       = "TCP"
          }
          port {
            name           = "torrent-udp"
            container_port = 6881
            protocol       = "UDP"
          }

          env {
            name  = "PUID"
            value = "1000"
          }
          env {
            name  = "PGID"
            value = "1000"
          }
          env {
            name  = "TZ"
            value = "America/New_York"
          }
          env {
            name  = "WEBUI_PORT"
            value = "8080"
          }
          env {
            name  = "TORRENTING_PORT"
            value = "6881"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "2"
              memory = "2Gi"
            }
          }

          security_context {
            allow_privilege_escalation = true
            capabilities {
              add  = ["CHOWN", "SETGID", "SETUID"]
              drop = ["ALL"]
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 30
            timeout_seconds       = 5
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
          }
          startup_probe {
            tcp_socket {
              port = 8080
            }
            failure_threshold = 30
            period_seconds    = 10
            timeout_seconds   = 1
          }

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }
          volume_mount {
            name       = "downloads"
            mount_path = "/downloads"
          }
          volume_mount {
            name       = "media-library"
            mount_path = "/media/library"
          }
        }

        volume {
          name = "config"
          persistent_volume_claim {
            claim_name = "qbittorrent-config-pvc"
          }
        }
        volume {
          name = "downloads"
          host_path {
            path = "/media/downloads"
            type = "DirectoryOrCreate"
          }
        }
        volume {
          name = "media-library"
          host_path {
            path = "/media/library"
            type = "Directory"
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].template[0].metadata[0].annotations,
    ]
  }
}

resource "kubernetes_service_v1" "qbittorrent" {
  count = var.enable_qbittorrent ? 1 : 0
  metadata {
    name      = "qbittorrent"
    namespace = "qbittorrent"
    labels    = merge(var.tags, { app = "qbittorrent" })
  }
  spec {
    type     = "ClusterIP"
    selector = { app = "qbittorrent" }
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
    port {
      name        = "torrent"
      port        = 6881
      target_port = 6881
      protocol    = "TCP"
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].cluster_ip,
      spec[0].cluster_ips,
    ]
  }
}

resource "kubernetes_ingress_v1" "qbittorrent" {
  count = var.enable_qbittorrent ? 1 : 0
  metadata {
    name      = "qbittorrent"
    namespace = "qbittorrent"
    labels    = merge(var.tags, { app = "qbittorrent" })
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "qbittorrent.${var.ingress_base_domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "qbittorrent"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}


# ===========================================================================
# local-path-storage - Rancher local-path-provisioner
# ===========================================================================

resource "kubernetes_namespace" "local_path_storage" {
  count = var.enable_local_path_storage ? 1 : 0
  metadata {
    name = "local-path-storage"
    labels = merge(var.tags, {
      name = "local-path-storage"
    })
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_config_map_v1" "local_path_config" {
  count = var.enable_local_path_storage ? 1 : 0
  metadata {
    name      = "local-path-config"
    namespace = "local-path-storage"
  }
  lifecycle { ignore_changes = [data, metadata[0].annotations] }
}

resource "kubernetes_service_account_v1" "local_path_provisioner_sa" {
  count = var.enable_local_path_storage ? 1 : 0
  metadata {
    name      = "local-path-provisioner-service-account"
    namespace = "local-path-storage"
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_cluster_role_v1" "local_path_provisioner_cr" {
  count    = var.enable_local_path_storage ? 1 : 0
  metadata { name = "local-path-provisioner-role" }
  rule {
    api_groups = [""]
    resources  = ["nodes", "persistentvolumeclaims", "configmaps", "pods", "pods/log"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["persistentvolumes"]
    verbs      = ["get", "list", "watch", "create", "patch", "update", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["get", "list", "watch"]
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_cluster_role_binding_v1" "local_path_provisioner_crb" {
  count    = var.enable_local_path_storage ? 1 : 0
  metadata { name = "local-path-provisioner-bind" }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "local-path-provisioner-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "local-path-provisioner-service-account"
    namespace = "local-path-storage"
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_deployment_v1" "local_path_provisioner" {
  count = var.enable_local_path_storage ? 1 : 0
  metadata {
    name      = "local-path-provisioner"
    namespace = "local-path-storage"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "local-path-provisioner" }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = "25%"
      }
    }
    template {
      metadata {
        labels = { app = "local-path-provisioner" }
      }
      spec {
        service_account_name = "local-path-provisioner-service-account"
        container {
          name    = "local-path-provisioner"
          image   = "rancher/local-path-provisioner:v0.0.30"
          command = ["local-path-provisioner", "--debug", "start", "--config", "/etc/config/config.json"]
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          env {
            name  = "CONFIG_MOUNT_PATH"
            value = "/etc/config/"
          }
          volume_mount {
            name       = "config-volume"
            mount_path = "/etc/config/"
          }
        }
        volume {
          name = "config-volume"
          config_map {
            name = "local-path-config"
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].template[0].metadata[0].annotations,
    ]
  }
}


# ===========================================================================
# Portfolio preview environments - dev & stage
# ===========================================================================

resource "kubernetes_namespace" "portfolio_dev" {
  count = var.enable_portfolio_dev ? 1 : 0
  metadata {
    name = "portfolio-dev"
    labels = merge(var.tags, {
      name                                 = "portfolio-dev"
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_deployment_v1" "portfolio_dev_web" {
  count = var.enable_portfolio_dev ? 1 : 0
  metadata {
    name      = "portfolio-web"
    namespace = "portfolio-dev"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "portfolio-web" }
    }
    template {
      metadata {
        labels = { app = "portfolio-web" }
      }
      spec {
        container {
          name  = "portfolio-web"
          image = "10.110.237.99:5000/portfolio/portfolio-web:dev"
          port {
            container_port = 80
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].template[0].metadata[0].annotations,
      spec[0].template[0].spec[0].container[0].image,
      spec[0].replicas,
    ]
  }
}

resource "kubernetes_service_v1" "portfolio_dev_web" {
  count = var.enable_portfolio_dev ? 1 : 0
  metadata {
    name      = "portfolio-web"
    namespace = "portfolio-dev"
  }
  spec {
    type     = "ClusterIP"
    selector = { app = "portfolio-web" }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].cluster_ip,
      spec[0].cluster_ips,
    ]
  }
}

resource "kubernetes_ingress_v1" "portfolio_dev_web" {
  count = var.enable_portfolio_dev ? 1 : 0
  metadata {
    name      = "portfolio-web"
    namespace = "portfolio-dev"
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "portfolio.dev.${var.ingress_base_domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "portfolio-web"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

# --- portfolio-stage ---

resource "kubernetes_namespace" "portfolio_stage" {
  count = var.enable_portfolio_stage ? 1 : 0
  metadata {
    name = "portfolio-stage"
    labels = merge(var.tags, {
      name                                 = "portfolio-stage"
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}

resource "kubernetes_deployment_v1" "portfolio_stage_web" {
  count = var.enable_portfolio_stage ? 1 : 0
  metadata {
    name      = "portfolio-web"
    namespace = "portfolio-stage"
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "portfolio-web" }
    }
    template {
      metadata {
        labels = { app = "portfolio-web" }
      }
      spec {
        container {
          name  = "portfolio-web"
          image = "harbor.local.lan/portfolio/portfolio-web:stage"
          port {
            container_port = 80
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].template[0].metadata[0].annotations,
      spec[0].template[0].spec[0].container[0].image,
      spec[0].replicas,
    ]
  }
}

resource "kubernetes_service_v1" "portfolio_stage_web" {
  count = var.enable_portfolio_stage ? 1 : 0
  metadata {
    name      = "portfolio-web"
    namespace = "portfolio-stage"
  }
  spec {
    type     = "ClusterIP"
    selector = { app = "portfolio-web" }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations,
      spec[0].cluster_ip,
      spec[0].cluster_ips,
    ]
  }
}

resource "kubernetes_ingress_v1" "portfolio_stage_web" {
  count = var.enable_portfolio_stage ? 1 : 0
  metadata {
    name      = "portfolio-web"
    namespace = "portfolio-stage"
  }
  spec {
    ingress_class_name = "traefik"
    rule {
      host = "portfolio.stage.${var.ingress_base_domain}"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "portfolio-web"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
  lifecycle { ignore_changes = [metadata[0].annotations] }
}
