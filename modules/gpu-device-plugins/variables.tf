variable "namespace" {
  description = "Namespace for GPU device plugin daemonsets"
  type        = string
  default     = "kube-system"
}

variable "enable_intel_gpu_plugin" {
  description = "Enable Intel GPU device plugin daemonset"
  type        = bool
  default     = true
}

variable "enable_amd_gpu_plugin" {
  description = "Enable AMD GPU device plugin daemonset"
  type        = bool
  default     = true
}

variable "enable_nvidia_gpu_plugin" {
  description = "Enable NVIDIA GPU device plugin daemonset"
  type        = bool
  default     = true
}

variable "intel_gpu_plugin_image" {
  description = "Container image for Intel GPU plugin"
  type        = string
  default     = "intel/intel-gpu-plugin:devel"
}

variable "amd_gpu_plugin_image" {
  description = "Container image for AMD GPU plugin"
  type        = string
  default     = "rocm/k8s-device-plugin"
}

variable "nvidia_gpu_plugin_image" {
  description = "Container image for NVIDIA GPU plugin"
  type        = string
  default     = "nvcr.io/nvidia/k8s-device-plugin:v0.14.5"
}

variable "nvidia_node_selector" {
  description = "Node selector used by NVIDIA GPU plugin daemonset"
  type        = map(string)
  default = {
    "kubernetes.io/hostname" = "k8s3"
  }
}

variable "tags" {
  description = "Labels applied to resources"
  type        = map(string)
  default     = {}
}