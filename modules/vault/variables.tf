variable "namespace" {
  description = "Namespace where Vault will be installed"
  type        = string
  default     = "vault"
}

variable "release_name" {
  description = "Helm release name for Vault"
  type        = string
  default     = "vault"
}

variable "chart_version" {
  description = "Vault Helm chart version"
  type        = string
  default     = "0.28.1"
}

variable "storage_size" {
  description = "Persistent volume size for Vault data"
  type        = string
  default     = "10Gi"
}

variable "storage_class" {
  description = "Storage class for Vault persistent volume"
  type        = string
  default     = "local-path"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}