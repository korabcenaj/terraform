variable "namespace" {
  description = "Namespace where Matrix Dendrite will be installed"
  type        = string
  default     = "matrix"
}

variable "name" {
  description = "Base resource name for Matrix Dendrite resources"
  type        = string
  default     = "matrix-dendrite"
}

variable "image" {
  description = "Container image for Matrix Dendrite monolith"
  type        = string
  default     = "matrixdotorg/dendrite-monolith:v0.14.1"
}

variable "server_name" {
  description = "Matrix server_name used for user IDs and federation (e.g. chat.local.lan)"
  type        = string
}

variable "public_base_url" {
  description = "Public base URL advertised by Dendrite (e.g. https://chat.local.lan/)"
  type        = string
}

variable "storage_size" {
  description = "Persistent volume size for Dendrite data"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class for Dendrite persistent volume"
  type        = string
  default     = "local-path"
}

variable "ingress_host" {
  description = "Hostname for Matrix Dendrite ingress (e.g. chat.local.lan)"
  type        = string
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer name used for Matrix ingress TLS"
  type        = string
  default     = "local-lan-ca"
}

variable "cpu_request" {
  description = "CPU request for Dendrite"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request for Dendrite"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU limit for Dendrite"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for Dendrite"
  type        = string
  default     = "512Mi"
}

variable "registration_shared_secret" {
  description = "Shared secret used for controlled user provisioning via create-account"
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.registration_shared_secret)) >= 24
    error_message = "registration_shared_secret must be at least 24 characters."
  }
}

variable "bootstrap_admin_enabled" {
  description = "Create a one-shot Kubernetes Job to create the initial Dendrite admin user"
  type        = bool
  default     = false
}

variable "bootstrap_admin_username" {
  description = "Username for first Dendrite admin user created by bootstrap job"
  type        = string
  default     = "admin"
}

variable "bootstrap_admin_password" {
  description = "Password for first Dendrite admin user created by bootstrap job"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition = (
      trimspace(var.bootstrap_admin_password) == "" ||
      length(trimspace(var.bootstrap_admin_password)) >= 12
    )
    error_message = "bootstrap_admin_password must be at least 12 characters when set."
  }
}

variable "oidc_enabled" {
  description = "Enable OIDC login against Keycloak"
  type        = bool
  default     = false
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL for Keycloak realm"
  type        = string
  default     = ""
}

variable "oidc_client_id" {
  description = "OIDC client ID for Dendrite"
  type        = string
  default     = "matrix-dendrite"
}

variable "oidc_client_secret" {
  description = "OIDC client secret for Dendrite"
  type        = string
  sensitive   = true
  default     = ""
}

variable "oidc_scopes" {
  description = "OIDC scopes requested by Dendrite"
  type        = list(string)
  default     = ["openid", "profile", "email"]
}

variable "federation_enabled" {
  description = "Enable Matrix federation with remote homeservers"
  type        = bool
  default     = false
}

variable "federation_domain_whitelist" {
  description = "Optional federation allow-list. Empty means unrestricted when federation_enabled is true"
  type        = list(string)
  default     = []
}

variable "well_known_enabled" {
  description = "Serve .well-known/matrix/client and .well-known/matrix/server endpoints"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
