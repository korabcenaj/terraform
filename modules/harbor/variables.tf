variable "namespace" {
  type        = string
  default     = "harbor"
  description = "Kubernetes namespace for Harbor."
}

variable "release_name" {
  type        = string
  default     = "harbor"
  description = "Helm release name."
}

variable "chart_version" {
  type        = string
  default     = "1.18.3"
  description = "Harbor Helm chart version."
}

variable "external_url" {
  type        = string
  description = "External URL for Harbor (e.g. https://harbor.local.lan)."
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Harbor admin account password."
}

variable "expose_type" {
  type        = string
  default     = "ingress"
  description = "Expose type: ingress, clusterIP, or loadBalancer."
  validation {
    condition     = contains(["ingress", "clusterIP", "loadBalancer"], var.expose_type)
    error_message = "expose_type must be ingress, clusterIP, or loadBalancer."
  }
}

variable "ingress_host" {
  type        = string
  default     = "harbor.local.lan"
  description = "Hostname used for Harbor ingress."
}

variable "ingress_class_name" {
  type        = string
  default     = "nginx"
  description = "IngressClass to use for Harbor."
}

variable "tls_enabled" {
  type        = bool
  default     = true
  description = "Enable TLS on the Harbor ingress."
}

variable "storage_class" {
  type        = string
  default     = ""
  description = "StorageClass for Harbor PVCs. Empty string uses cluster default."
}

variable "registry_storage_size" {
  type        = string
  default     = "20Gi"
  description = "PVC size for container image storage."
}

variable "enable_trivy" {
  type        = bool
  default     = true
  description = "Enable built-in Trivy vulnerability scanner."
}

variable "extra_values" {
  type        = map(string)
  default     = {}
  description = "Additional Helm values to pass as set blocks."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Labels to apply to all created resources."
}
