variable "enable_linkerd_viz" {
  description = "Whether Linkerd Viz (dashboard) is installed"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
