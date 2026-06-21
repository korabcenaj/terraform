variable "release_name" {
  description = "Helm release name for Longhorn"
  type        = string
  default     = "longhorn"
}

variable "chart_version" {
  description = "Longhorn Helm chart version"
  type        = string
  default     = "1.12.0"
}

variable "namespace" {
  description = "Namespace for Longhorn"
  type        = string
  default     = "longhorn-system"
}

variable "timeout" {
  description = "Helm install timeout in seconds"
  type        = number
  default     = 600
}

variable "default_data_path" {
  description = "Default path for Longhorn storage on nodes"
  type        = string
  default     = "/var/lib/longhorn"
}

variable "persistence_default_class" {
  description = "Set Longhorn as the default StorageClass"
  type        = string
  default     = "false"
}

variable "default_replica_count" {
  description = "Default number of replicas for Longhorn volumes"
  type        = number
  default     = 2
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
