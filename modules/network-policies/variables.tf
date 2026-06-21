variable "enable_portfolio_netpol" {
  description = "Enable NetworkPolicy for portfolio"
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

variable "enable_oauth2_proxy_netpol" {
  description = "Enable NetworkPolicy for oauth2-proxy"
  type        = bool
  default     = true
}

variable "oauth2_proxy_namespace" {
  description = "oauth2-proxy namespace name"
  type        = string
  default     = "oauth2-proxy"
}

variable "enable_harbor_netpol" {
  description = "Enable NetworkPolicy for harbor"
  type        = bool
  default     = true
}

variable "harbor_namespace" {
  description = "Harbor namespace name"
  type        = string
  default     = "harbor"
}

variable "enable_traefik_netpol" {
  description = "Enable NetworkPolicy for traefik"
  type        = bool
  default     = true
}

variable "traefik_namespace" {
  description = "traefik namespace name"
  type        = string
  default     = "traefik"
}
