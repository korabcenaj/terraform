variable "release_name" {
  description = "Helm release name for MetalLB"
  type        = string
  default     = "metallb"
}

variable "chart_version" {
  description = "MetalLB Helm chart version"
  type        = string
  default     = "0.15.3"
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "address_pool_name" {
  description = "Name of the MetalLB IPAddressPool"
  type        = string
  default     = "home-lab-pool"
}

variable "address_range" {
  description = "IP address range for MetalLB (CIDR or range)"
  type        = string
  default     = "192.168.0.200-192.168.0.220"
}

variable "l2_advertisement_name" {
  description = "Name of the MetalLB L2Advertisement"
  type        = string
  default     = "home-lab-l2"
}
