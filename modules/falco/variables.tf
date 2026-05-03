variable "namespace" {
  type        = string
  default     = "falco"
  description = "Kubernetes namespace for Falco."
}

variable "release_name" {
  type        = string
  default     = "falco"
  description = "Helm release name."
}

variable "chart_version" {
  type        = string
  default     = "8.0.2"
  description = "Falco Helm chart version."
}

variable "driver_kind" {
  type        = string
  default     = "ebpf"
  description = "Falco driver type: ebpf, module, or modern_ebpf."
  validation {
    condition     = contains(["ebpf", "module", "modern_ebpf"], var.driver_kind)
    error_message = "driver_kind must be one of: ebpf, module, modern_ebpf."
  }
}

variable "enable_falcosidekick" {
  type        = bool
  default     = false
  description = "Enable Falcosidekick sidecar for alert forwarding."
}

variable "enable_metrics" {
  type        = bool
  default     = false
  description = "Enable Prometheus metrics endpoint."
}

variable "log_level" {
  type        = string
  default     = "info"
  description = "Falco log level: emergency, alert, critical, error, warning, notice, info, debug."
  validation {
    condition     = contains(["emergency", "alert", "critical", "error", "warning", "notice", "info", "debug"], var.log_level)
    error_message = "Invalid log_level."
  }
}

variable "extra_values" {
  type        = map(string)
  default     = {}
  description = "Additional Helm values to pass as set blocks."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all created resources."
}
