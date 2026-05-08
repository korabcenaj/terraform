variable "namespace" {
  description = "Namespace where Matrix Synapse will be installed"
  type        = string
  default     = "matrix"
}

variable "name" {
  description = "Base resource name for Matrix Synapse resources"
  type        = string
  default     = "matrix-synapse"
}

variable "image" {
  description = "Container image for Matrix Synapse"
  type        = string
  default     = "matrixdotorg/synapse:v1.131.0"
}

variable "server_name" {
  description = "Matrix server_name used for user IDs and federation (e.g. chat.local.lan)"
  type        = string
}

variable "public_base_url" {
  description = "Public base URL advertised by Synapse (e.g. https://chat.local.lan/)"
  type        = string
}

variable "report_stats" {
  description = "Whether Synapse may report anonymous stats to the Matrix project"
  type        = bool
  default     = false
}

variable "storage_size" {
  description = "Persistent volume size for Synapse data"
  type        = string
  default     = "20Gi"
}

variable "storage_class" {
  description = "Storage class for Synapse persistent volume"
  type        = string
  default     = "local-path"
}

variable "ingress_host" {
  description = "Hostname for Matrix Synapse ingress (e.g. chat.local.lan)"
  type        = string
}

variable "cluster_issuer" {
  description = "cert-manager ClusterIssuer name used for Matrix ingress TLS"
  type        = string
  default     = "local-lan-ca"
}

variable "cpu_request" {
  description = "CPU request for Synapse"
  type        = string
  default     = "250m"
}

variable "memory_request" {
  description = "Memory request for Synapse"
  type        = string
  default     = "512Mi"
}

variable "cpu_limit" {
  description = "CPU limit for Synapse"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for Synapse"
  type        = string
  default     = "2Gi"
}

variable "registration_shared_secret" {
  description = "Shared secret used for controlled user provisioning via register_new_matrix_user"
  type        = string
  sensitive   = true

  validation {
    condition     = length(trimspace(var.registration_shared_secret)) >= 24
    error_message = "registration_shared_secret must be at least 24 characters."
  }
}

variable "bootstrap_admin_enabled" {
  description = "Create a one-shot Kubernetes Job to create the initial Synapse admin user"
  type        = bool
  default     = false
}

variable "bootstrap_admin_username" {
  description = "Username for first Synapse admin user created by bootstrap job"
  type        = string
  default     = "admin"
}

variable "bootstrap_admin_password" {
  description = "Password for first Synapse admin user created by bootstrap job"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition = (
      !var.bootstrap_admin_enabled ||
      length(trimspace(var.bootstrap_admin_password)) >= 12
    )
    error_message = "bootstrap_admin_password must be at least 12 characters when bootstrap_admin_enabled is true."
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
  description = "OIDC client ID for Synapse"
  type        = string
  default     = "matrix-synapse"
}

variable "oidc_client_secret" {
  description = "OIDC client secret for Synapse"
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = !var.oidc_enabled || trimspace(var.oidc_client_secret) != ""
    error_message = "oidc_client_secret is required when oidc_enabled is true."
  }
}

variable "oidc_scopes" {
  description = "OIDC scopes requested by Synapse"
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
