variable "namespace" {
  description = "Namespace where Tempo will be installed"
  type        = string
  default     = "tracing"
}

variable "release_name" {
  description = "Helm release name for Tempo"
  type        = string
  default     = "tempo"
}

variable "chart_version" {
  description = "Tempo Helm chart version"
  type        = string
  default     = "1.17.2"
}

variable "storage_size" {
  description = "Persistent volume size for Tempo traces"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class for Tempo persistent volume"
  type        = string
  default     = "local-path"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}