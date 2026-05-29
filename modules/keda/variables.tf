variable "release_name" {
  description = "Helm release name for KEDA"
  type        = string
  default     = "keda"
}

variable "chart_version" {
  description = "KEDA Helm chart version"
  type        = string
  default     = "2.19.0"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
