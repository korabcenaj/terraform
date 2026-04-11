variable "enable_portfolio_pdb" {
  description = "Enable PodDisruptionBudget for portfolio"
  type        = bool
  default     = true
}

variable "enable_qbittorrent_pdb" {
  description = "Enable PodDisruptionBudget for qbittorrent"
  type        = bool
  default     = true
}

variable "enable_jellyfin_pdb" {
  description = "Enable PodDisruptionBudget for jellyfin"
  type        = bool
  default     = true
}

variable "enable_pihole_pdb" {
  description = "Enable PodDisruptionBudget for pihole"
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

variable "portfolio_max_unavailable" {
  description = "Maximum unavailable portfolio pods during disruptions"
  type        = number
  default     = 1
}

variable "qbittorrent_max_unavailable" {
  description = "Maximum unavailable qbittorrent pods during disruptions"
  type        = number
  default     = 1
}

variable "jellyfin_max_unavailable" {
  description = "Maximum unavailable jellyfin pods during disruptions"
  type        = number
  default     = 1
}

variable "pihole_max_unavailable" {
  description = "Maximum unavailable pihole pods during disruptions"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
