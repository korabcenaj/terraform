variable "release_name" {
  description = "Helm release name for Gitea"
  type        = string
  default     = "gitea"
}

variable "chart_version" {
  description = "Gitea Helm chart version"
  type        = string
  default     = "12.5.3"
}

variable "image_tag" {
  description = "Gitea container image tag"
  type        = string
  default     = "1.24.1"
}

variable "ingress_host" {
  description = "Gitea ingress hostname"
  type        = string
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "traefik"
}

variable "admin_username" {
  description = "Gitea admin username"
  type        = string
  default     = "gitea"
}

variable "admin_password" {
  description = "Gitea admin password"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "Gitea admin email"
  type        = string
  default     = "admin@local.lan"
}

variable "postgresql_password" {
  description = "Gitea PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "storage_size" {
  description = "Gitea persistent volume size"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class for Gitea persistent volumes"
  type        = string
  default     = "local-path"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
