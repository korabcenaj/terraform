variable "namespace" {
  description = "Namespace where cert-manager will be installed"
  type        = string
  default     = "cert-manager"
}

variable "release_name" {
  description = "Helm release name for cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "chart_version" {
  description = "cert-manager Helm chart version"
  type        = string
  default     = "v1.17.1"
}

variable "manage_controller_install" {
  description = "Whether Terraform should manage the cert-manager controller installation via Helm, or only manage the namespace and issuer bootstrap objects"
  type        = bool
  default     = true
}

variable "replicas" {
  description = "Number of cert-manager controller replicas"
  type        = number
  default     = 1
}

variable "acme_email" {
  description = "Email address for ACME (Let's Encrypt) issuer registration"
  type        = string
  default     = ""
}

variable "create_selfsigned_issuer" {
  description = "Create a self-signed ClusterIssuer for bootstrap"
  type        = bool
  default     = true
}

variable "create_local_ca_issuer" {
  description = "Create the local-lan-ca ClusterIssuer used by other modules"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
