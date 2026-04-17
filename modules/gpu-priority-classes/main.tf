resource "kubernetes_priority_class_v1" "gpu_interactive" {
  metadata {
    name = var.interactive_priority_name
    labels = merge(var.tags, {
      app = "gpu-workloads"
    })
  }

  value             = var.interactive_priority_value
  global_default    = false
  preemption_policy = "PreemptLowerPriority"
  description       = "High-priority class for latency-sensitive GPU inference or interactive AI jobs."
}

resource "kubernetes_priority_class_v1" "gpu_batch" {
  metadata {
    name = var.batch_priority_name
    labels = merge(var.tags, {
      app = "gpu-workloads"
    })
  }

  value             = var.batch_priority_value
  global_default    = false
  preemption_policy = "Never"
  description       = "Lower-priority class for long-running GPU batch/training jobs."
}
