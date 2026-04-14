variable "namespace" {
  description = "Namespace where Keycloak will be installed"
  type        = string
  default     = "keycloak"
}

variable "release_name" {
  description = "Helm release name for Keycloak"
  type        = string
  default     = "keycloak"
}

variable "chart_version" {
  description = "Keycloak Helm chart version"
  type        = string
  default     = "25.2.0"
}

variable "admin_user" {
  description = "Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "postgresql_username" {
  description = "PostgreSQL username for Keycloak"
  type        = string
  default     = "keycloak"
}

variable "postgresql_password" {
  description = "PostgreSQL password for the bundled Keycloak database"
  type        = string
  sensitive   = true
}

variable "postgresql_database" {
  description = "PostgreSQL database name for Keycloak"
  type        = string
  default     = "keycloak"
}

variable "postgresql_storage_class" {
  description = "Storage class for the bundled PostgreSQL persistent volume"
  type        = string
  default     = "local-path"
}

variable "postgresql_storage_size" {
  description = "Persistent volume size for the bundled PostgreSQL database"
  type        = string
  default     = "8Gi"
}

variable "ingress_host" {
  description = "Hostname for the Keycloak ingress (e.g. sso.local.lan)"
  type        = string
}

variable "realm" {
  description = "Primary realm name to use for application OIDC clients"
  type        = string
  default     = "homelab"
}

variable "bootstrap_enabled" {
  description = "Enable declarative realm and OIDC client bootstrap using keycloak-config-cli"
  type        = bool
  default     = true
}

variable "argocd_client_id" {
  description = "OIDC client ID to bootstrap for Argo CD"
  type        = string
  sensitive   = true
  default     = "argocd"
}

variable "argocd_client_secret" {
  description = "OIDC client secret to bootstrap for Argo CD"
  type        = string
  sensitive   = true
}

variable "argocd_redirect_uris" {
  description = "Allowed redirect URIs for the Argo CD OIDC client"
  type        = list(string)
  default     = []
}

variable "argocd_web_origins" {
  description = "Allowed web origins for the Argo CD OIDC client"
  type        = list(string)
  default     = []
}

variable "grafana_client_id" {
  description = "OIDC client ID to bootstrap for Grafana"
  type        = string
  sensitive   = true
  default     = "grafana"
}

variable "grafana_client_secret" {
  description = "OIDC client secret to bootstrap for Grafana"
  type        = string
  sensitive   = true
}

variable "grafana_redirect_uris" {
  description = "Allowed redirect URIs for the Grafana OIDC client"
  type        = list(string)
  default     = []
}

variable "grafana_web_origins" {
  description = "Allowed web origins for the Grafana OIDC client"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
