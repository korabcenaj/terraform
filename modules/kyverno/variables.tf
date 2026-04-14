variable "namespace" {
  description = "Namespace where Kyverno will be installed"
  type        = string
  default     = "kyverno"
}

variable "release_name" {
  description = "Helm release name for Kyverno"
  type        = string
  default     = "kyverno"
}

variable "chart_version" {
  description = "Kyverno Helm chart version"
  type        = string
  default     = "3.2.6"
}

variable "enforcement_mode" {
  description = "Policy validation failure action: 'Audit' logs violations, 'Enforce' blocks non-compliant resources"
  type        = string
  default     = "Audit"

  validation {
    condition     = contains(["Audit", "Enforce"], var.enforcement_mode)
    error_message = "enforcement_mode must be either 'Audit' or 'Enforce'."
  }
}

variable "enable_policies" {
  description = "Create ClusterPolicy resources. Requires Kyverno CRDs to be registered in the cluster. Enable only after the Helm release has been applied."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
