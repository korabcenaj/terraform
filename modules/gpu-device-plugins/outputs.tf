output "intel_daemonset_name" {
  description = "Intel GPU plugin daemonset name"
  value       = var.enable_intel_gpu_plugin ? kubernetes_daemon_set_v1.intel_gpu_plugin[0].metadata[0].name : null
}

output "amd_daemonset_name" {
  description = "AMD GPU plugin daemonset name"
  value       = var.enable_amd_gpu_plugin ? kubernetes_daemon_set_v1.amd_gpu_plugin[0].metadata[0].name : null
}

output "nvidia_daemonset_name" {
  description = "NVIDIA GPU plugin daemonset name"
  value       = var.enable_nvidia_gpu_plugin ? kubernetes_daemon_set_v1.nvidia_gpu_plugin[0].metadata[0].name : null
}
