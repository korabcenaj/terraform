variable "enable_portfolio_netpol" {
  description = "Enable NetworkPolicy for portfolio"
  type        = bool
  default     = true
}

variable "enable_qbittorrent_netpol" {
  description = "Enable NetworkPolicy for qbittorrent"
  type        = bool
  default     = true
}

variable "enable_jellyfin_netpol" {
  description = "Enable NetworkPolicy for jellyfin"
  type        = bool
  default     = true
}

variable "enable_pihole_netpol" {
  description = "Enable NetworkPolicy for pihole"
  type        = bool
  default     = true
}

variable "enable_n8n_netpol" {
  description = "Enable NetworkPolicy for n8n"
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

variable "n8n_namespace" {
  description = "n8n namespace name"
  type        = string
  default     = "n8n"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
