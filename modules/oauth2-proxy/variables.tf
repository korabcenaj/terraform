variable "namespace" {
  description = "Namespace where OAuth2 Proxy will be installed"
  type        = string
  default     = "oauth2-proxy"
}

variable "release_name" {
  description = "Helm release name for OAuth2 Proxy"
  type        = string
  default     = "oauth2-proxy"
}

variable "chart_version" {
  description = "OAuth2 Proxy Helm chart version"
  type        = string
  default     = "7.7.1"
}

variable "oauth2_provider" {
  description = "OAuth2 provider type (e.g. github, oidc, google)"
  type        = string
  default     = "github"
}

variable "email_domain" {
  description = "Allowed email domain for authentication. Use '*' to allow any domain."
  type        = string
  default     = "*"
}

variable "client_id" {
  description = "OAuth2 application client ID"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "OAuth2 application client secret"
  type        = string
  sensitive   = true
}

variable "cookie_secret" {
  description = "Cookie encryption secret — must be 16, 24, or 32 bytes base64-encoded. Generate with: openssl rand -base64 32 | tr -- '+/' '-_' | tr -d '='"
  type        = string
  sensitive   = true
}

variable "ingress_host" {
  description = "Hostname for OAuth2 Proxy ingress (e.g. auth.local.lan)"
  type        = string
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
