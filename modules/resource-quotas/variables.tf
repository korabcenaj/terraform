variable "enable_portfolio_quota" {
  description = "Enable ResourceQuota for portfolio namespace"
  type        = bool
  default     = true
}

variable "enable_jellyfin_quota" {
  description = "Enable ResourceQuota for jellyfin namespace"
  type        = bool
  default     = true
}

variable "enable_pihole_quota" {
  description = "Enable ResourceQuota for pihole namespace"
  type        = bool
  default     = true
}

variable "enable_argo_quota" {
  description = "Enable ResourceQuota for argo namespace"
  type        = bool
  default     = true
}

variable "enable_gitea_quota" {
  description = "Enable ResourceQuota for git namespace"
  type        = bool
  default     = true
}

variable "enable_harbor_quota" {
  description = "Enable ResourceQuota for harbor namespace"
  type        = bool
  default     = true
}

variable "enable_buildkit_quota" {
  description = "Enable ResourceQuota for buildkit namespace"
  type        = bool
  default     = true
}

variable "enable_awx_quota" {
  description = "Enable ResourceQuota for awx namespace"
  type        = bool
  default     = true
}

variable "enable_matrix_quota" {
  description = "Enable ResourceQuota for matrix namespace"
  type        = bool
  default     = true
}

variable "enable_n8n_quota" {
  description = "Enable ResourceQuota for n8n namespace"
  type        = bool
  default     = true
}

variable "portfolio_namespace" {
  description = "Portfolio namespace name"
  type        = string
  default     = "portfolio"
}

variable "jellyfin_namespace" {
  description = "Jellyfin namespace name"
  type        = string
  default     = "jellyfin"
}

variable "pihole_namespace" {
  description = "Pi-hole namespace name"
  type        = string
  default     = "pihole"
}

variable "argo_namespace" {
  description = "Argo namespace name"
  type        = string
  default     = "argo"
}

variable "git_namespace" {
  description = "Gitea namespace name"
  type        = string
  default     = "git"
}

variable "harbor_namespace" {
  description = "Harbor namespace name"
  type        = string
  default     = "harbor"
}

variable "buildkit_namespace" {
  description = "BuildKit namespace name"
  type        = string
  default     = "buildkit"
}

variable "awx_namespace" {
  description = "AWX namespace name"
  type        = string
  default     = "awx"
}

variable "matrix_namespace" {
  description = "Matrix namespace name"
  type        = string
  default     = "matrix"
}

variable "n8n_namespace" {
  description = "n8n namespace name"
  type        = string
  default     = "n8n"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
