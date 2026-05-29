variable "release_name" {
  description = "Helm release name for Harbor"
  type        = string
  default     = "harbor"
}

variable "chart_version" {
  description = "Harbor Helm chart version"
  type        = string
  default     = "1.19.0"
}

variable "ingress_host" {
  description = "Harbor ingress hostname"
  type        = string
}

variable "ingress_class_name" {
  description = "Ingress class name"
  type        = string
  default     = "traefik"
}

variable "admin_password" {
  description = "Harbor admin password"
  type        = string
  sensitive   = true
}

variable "storage_class" {
  description = "Storage class for Harbor persistent volumes"
  type        = string
  default     = "local-path"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
