variable "namespaces_with_policies" {
  description = "Namespaces to apply network policies to"
  type        = list(string)
  default     = []
}

variable "coredns_local_domain" {
  description = "Private DNS domain to forward to the local DNS server (e.g. local.lan)"
  type        = string
  default     = "local.lan"

  validation {
    condition = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", trimspace(lower(var.coredns_local_domain))))
    error_message = "coredns_local_domain must be a valid lowercase DNS domain, for example local.lan."
  }
}

variable "coredns_local_dns_ip" {
  description = "Upstream resolver for private domain forwarding (IPv4 or DNS name, e.g. pihole.pihole.svc.cluster.local)"
  type        = string
  default     = ""

  validation {
    condition = (
      trimspace(var.coredns_local_dns_ip) == "" ||
      can(regex("^(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})(\\.(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})){3}$", trimspace(var.coredns_local_dns_ip))) ||
      can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", trimspace(lower(var.coredns_local_dns_ip))))
    )
    error_message = "coredns_local_dns_ip must be empty, a valid IPv4 address, or a valid DNS hostname."
  }
}
