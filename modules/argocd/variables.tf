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

variable "oidc_enabled" {
  description = "Enable native OIDC login for Argo CD"
  type        = bool
  default     = false
}

variable "oidc_name" {
  description = "Display name for the OIDC provider in the Argo CD login screen"
  type        = string
  default     = "Keycloak"
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL used by Argo CD"
  type        = string
  default     = ""
}

variable "oidc_client_id" {
  description = "OIDC client ID for Argo CD"
  type        = string
  sensitive   = true
  default     = ""
}

variable "oidc_client_secret" {
  description = "OIDC client secret for Argo CD"
  type        = string
  sensitive   = true
  default     = ""
}

variable "oidc_scopes" {
  description = "OIDC scopes requested by Argo CD"
  type        = list(string)
  default     = ["openid", "profile", "email", "groups"]
}

variable "ingress_host" {
  description = "Hostname for Argo CD server ingress (e.g. argocd.local.lan)"
  type        = string
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}