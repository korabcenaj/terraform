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

variable "oidc_root_ca_pem" {
  description = "Optional PEM-encoded root CA used to verify the OIDC provider TLS certificate"
  type        = string
  default     = ""
}

variable "oidc_scopes" {
  description = "OIDC scopes requested by Argo CD"
  type        = list(string)
  default     = ["openid", "profile", "email"]
}

variable "ingress_host" {
  description = "Hostname for Argo CD server ingress (e.g. argocd.local.lan)"
  type        = string
}

variable "create_bootstrap_app_project" {
  description = "Create a platform AppProject in Argo CD after install"
  type        = bool
  default     = false
}

variable "bootstrap_project_name" {
  description = "Name of the Argo CD AppProject to create"
  type        = string
  default     = "platform"
}

variable "create_bootstrap_application" {
  description = "Create a bootstrap Application in Argo CD pointing at a Git repo"
  type        = bool
  default     = false
}

variable "bootstrap_app_name" {
  description = "Name of the bootstrap Argo CD Application"
  type        = string
  default     = "platform-bootstrap"
}

variable "bootstrap_repo_url" {
  description = "Git repository URL for the bootstrap Application"
  type        = string
  default     = ""
}

variable "bootstrap_repo_revision" {
  description = "Git ref (branch/tag/commit) for the bootstrap Application"
  type        = string
  default     = "HEAD"
}

variable "bootstrap_repo_path" {
  description = "Path within the repository containing the Application manifests"
  type        = string
  default     = "."
}

variable "bootstrap_auto_sync" {
  description = "Enable automated sync (prune + self-heal) for the bootstrap Application. Set to false for initial rollout."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}