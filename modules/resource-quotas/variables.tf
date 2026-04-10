variable "enable_portfolio_quota" {
  description = "Enable ResourceQuota for portfolio namespace"
  type        = bool
  default     = true
}

variable "enable_qbittorrent_quota" {
  description = "Enable ResourceQuota for qbittorrent namespace"
  type        = bool
  default     = true
}

variable "enable_jellyfin_quota" {
  description = "Enable ResourceQuota for jellyfin namespace"
  type        = bool
  default     = true
}

variable "enable_pihole_quota" {
  description = "Enable ResourceQuota for pihole namespace"
  type        = bool
  default     = true
}

variable "portfolio_namespace" {
  description = "Portfolio namespace name"
  type        = string
}

variable "qbittorrent_namespace" {
  description = "qBittorrent namespace name"
  type        = string
}

variable "jellyfin_namespace" {
  description = "Jellyfin namespace name"
  type        = string
}

variable "pihole_namespace" {
  description = "Pi-hole namespace name"
  type        = string
}

# Portfolio quotas
variable "portfolio_pod_limit" {
  description = "Max pods in portfolio namespace"
  type        = string
  default     = "10"
}

variable "portfolio_cpu_request_quota" {
  description = "Total CPU requests quota for portfolio"
  type        = string
  default     = "2"
}

variable "portfolio_memory_request_quota" {
  description = "Total memory requests quota for portfolio"
  type        = string
  default     = "2Gi"
}

variable "portfolio_cpu_limit_quota" {
  description = "Total CPU limits quota for portfolio"
  type        = string
  default     = "4"
}

variable "portfolio_memory_limit_quota" {
  description = "Total memory limits quota for portfolio"
  type        = string
  default     = "4Gi"
}

# qBittorrent quotas
variable "qbittorrent_pod_limit" {
  description = "Max pods in qbittorrent namespace"
  type        = string
  default     = "10"
}

variable "qbittorrent_cpu_request_quota" {
  description = "Total CPU requests quota for qbittorrent"
  type        = string
  default     = "2"
}

variable "qbittorrent_memory_request_quota" {
  description = "Total memory requests quota for qbittorrent"
  type        = string
  default     = "2Gi"
}

variable "qbittorrent_cpu_limit_quota" {
  description = "Total CPU limits quota for qbittorrent"
  type        = string
  default     = "4"
}

variable "qbittorrent_memory_limit_quota" {
  description = "Total memory limits quota for qbittorrent"
  type        = string
  default     = "4Gi"
}

# Jellyfin quotas
variable "jellyfin_pod_limit" {
  description = "Max pods in jellyfin namespace"
  type        = string
  default     = "10"
}

variable "jellyfin_cpu_request_quota" {
  description = "Total CPU requests quota for jellyfin"
  type        = string
  default     = "3"
}

variable "jellyfin_memory_request_quota" {
  description = "Total memory requests quota for jellyfin"
  type        = string
  default     = "3Gi"
}

variable "jellyfin_cpu_limit_quota" {
  description = "Total CPU limits quota for jellyfin"
  type        = string
  default     = "6"
}

variable "jellyfin_memory_limit_quota" {
  description = "Total memory limits quota for jellyfin"
  type        = string
  default     = "6Gi"
}

# Pi-hole quotas
variable "pihole_pod_limit" {
  description = "Max pods in pihole namespace"
  type        = string
  default     = "5"
}

variable "pihole_cpu_request_quota" {
  description = "Total CPU requests quota for pihole"
  type        = string
  default     = "1"
}

variable "pihole_memory_request_quota" {
  description = "Total memory requests quota for pihole"
  type        = string
  default     = "2Gi"
}

variable "pihole_cpu_limit_quota" {
  description = "Total CPU limits quota for pihole"
  type        = string
  default     = "2"
}

variable "pihole_memory_limit_quota" {
  description = "Total memory limits quota for pihole"
  type        = string
  default     = "2Gi"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
