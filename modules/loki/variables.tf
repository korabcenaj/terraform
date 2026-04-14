variable "namespace" {
  description = "Namespace where Loki and Promtail will be installed"
  type        = string
  default     = "logging"
}

variable "release_name" {
  description = "Helm release name for Loki"
  type        = string
  default     = "loki"
}

variable "chart_version" {
  description = "loki-stack Helm chart version"
  type        = string
  default     = "2.10.2"
}

variable "loki_storage_size" {
  description = "Persistent volume size for Loki"
  type        = string
  default     = "20Gi"
}

variable "loki_storage_class" {
  description = "Storage class for Loki persistence"
  type        = string
  default     = "local-path"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}