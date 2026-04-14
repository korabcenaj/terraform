variable "namespace" {
  description = "Namespace where MinIO will be installed"
  type        = string
  default     = "minio"
}

variable "release_name" {
  description = "Helm release name for MinIO"
  type        = string
  default     = "minio"
}

variable "chart_version" {
  description = "MinIO Helm chart version"
  type        = string
  default     = "5.4.0"
}

variable "root_user" {
  description = "MinIO root username"
  type        = string
}

variable "root_password" {
  description = "MinIO root password"
  type        = string
  sensitive   = true
}

variable "storage_size" {
  description = "Persistent volume size for MinIO"
  type        = string
  default     = "50Gi"
}

variable "storage_class" {
  description = "Storage class for MinIO persistence"
  type        = string
  default     = "local-path"
}

variable "ingress_host" {
  description = "Hostname for MinIO console ingress (e.g. minio.local.lan)"
  type        = string
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}