variable "namespace" {
  type        = string
  default     = "metallb-system"
  description = "Kubernetes namespace for MetalLB."
}

variable "release_name" {
  type        = string
  default     = "metallb"
  description = "Helm release name."
}

variable "chart_version" {
  type        = string
  default     = "0.15.3"
  description = "MetalLB Helm chart version."
}

variable "ip_pool_name" {
  type        = string
  default     = "default-pool"
  description = "Name for the IPAddressPool and L2Advertisement."
}

variable "ip_pool_addresses" {
  type        = string
  default     = ""
  description = "CIDR or range for LoadBalancer IPs (e.g. 192.168.1.200-192.168.1.220). Leave empty to skip CRD creation."
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
