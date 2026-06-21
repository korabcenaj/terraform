locals {
  common_labels = merge(var.tags, {
    "app.kubernetes.io/managed-by" = "terraform"
  })
}

resource "kubernetes_daemon_set_v1" "intel_gpu_plugin" {
  count = var.enable_intel_gpu_plugin ? 1 : 0

  metadata {
    name      = "intel-gpu-plugin"
    namespace = var.namespace
    labels = merge(local.common_labels, {
      app = "intel-gpu-plugin"
    })
  }

  spec {
    selector {
      match_labels = {
        app = "intel-gpu-plugin"
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          app = "intel-gpu-plugin"
        })
      }

      spec {
        automount_service_account_token = true
        enable_service_links            = true

        node_selector = {
          "kubernetes.io/arch" = "amd64"
        }

        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          name              = "intel-gpu-plugin"
          image             = var.intel_gpu_plugin_image
          image_pull_policy = "IfNotPresent"

          security_context {
            privileged                 = true
            allow_privilege_escalation = true
          }

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          volume_mount {
            name       = "devfs"
            mount_path = "/dev/dri"
            read_only  = true
          }

          volume_mount {
            name       = "sysfsdrm"
            mount_path = "/sys/class/drm"
            read_only  = true
          }

          volume_mount {
            name       = "kubeletsockets"
            mount_path = "/var/lib/kubelet/device-plugins"
          }
        }

        volume {
          name = "devfs"
          host_path {
            path = "/dev/dri"
          }
        }

        volume {
          name = "sysfsdrm"
          host_path {
            path = "/sys/class/drm"
          }
        }

        volume {
          name = "kubeletsockets"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_daemon_set_v1" "amd_gpu_plugin" {
  count = var.enable_amd_gpu_plugin ? 1 : 0

  metadata {
    name      = "amdgpu-device-plugin-daemonset"
    namespace = var.namespace
    labels = merge(local.common_labels, {
      name = "amdgpu-dp-ds"
    })
  }

  spec {
    selector {
      match_labels = {
        name = "amdgpu-dp-ds"
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          name = "amdgpu-dp-ds"
        })
      }

      spec {
        automount_service_account_token = true
        enable_service_links            = true

        node_selector = {
          "kubernetes.io/arch" = "amd64"
        }

        priority_class_name = "system-node-critical"

        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }

        toleration {
          key      = "node-role.kubernetes.io/control-plane"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          name              = "amdgpu-dp-cntr"
          image             = var.amd_gpu_plugin_image
          image_pull_policy = "Always"

          security_context {
            privileged                 = true
            allow_privilege_escalation = true
            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "dp"
            mount_path = "/var/lib/kubelet/device-plugins"
          }

          volume_mount {
            name       = "sys"
            mount_path = "/sys"
          }
        }

        volume {
          name = "dp"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }

        volume {
          name = "sys"
          host_path {
            path = "/sys"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_daemon_set_v1" "nvidia_gpu_plugin" {
  count = var.enable_nvidia_gpu_plugin ? 1 : 0

  metadata {
    name      = "nvidia-device-plugin-daemonset"
    namespace = var.namespace
    labels = merge(local.common_labels, {
      name = "nvidia-device-plugin-ds"
    })
  }

  spec {
    selector {
      match_labels = {
        name = "nvidia-device-plugin-ds"
      }
    }

    template {
      metadata {
        labels = merge(local.common_labels, {
          name = "nvidia-device-plugin-ds"
        })
      }

      spec {
        automount_service_account_token = true
        enable_service_links            = true

        node_selector = var.nvidia_node_selector

        toleration {
          key      = "nvidia.com/gpu"
          operator = "Exists"
          effect   = "NoSchedule"
        }

        container {
          name  = "nvidia-device-plugin-ctr"
          image = var.nvidia_gpu_plugin_image

          env {
            name  = "FAIL_ON_INIT_ERROR"
            value = "false"
          }

          env {
            name  = "LD_LIBRARY_PATH"
            value = "/host-libs"
          }

          security_context {
            privileged = true
          }

          volume_mount {
            name       = "device-plugin"
            mount_path = "/var/lib/kubelet/device-plugins"
          }

          volume_mount {
            name       = "nvidia-ml"
            mount_path = "/host-libs/libnvidia-ml.so.1"
          }
        }

        volume {
          name = "device-plugin"
          host_path {
            path = "/var/lib/kubelet/device-plugins"
          }
        }

        volume {
          name = "nvidia-ml"
          host_path {
            path = "/usr/lib64/libnvidia-ml.so.1"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}
