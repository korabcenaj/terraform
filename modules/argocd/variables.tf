variable "namespace" {
  description = "Namespace where Argo CD will be installed"
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "7.8.5"
}

variable "admin_password_bcrypt" {
  description = "Optional bcrypt hash for Argo CD admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}