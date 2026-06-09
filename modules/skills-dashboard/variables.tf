variable "enable_skills_dashboard" {
  type        = bool
  default     = true
  description = "Enable the skills dashboard"
}

variable "skills_dashboard_image" {
  type        = string
  default     = "192.168.0.83:30002/library/skills-dashboard:latest"
  description = "Skills dashboard container image"
}

variable "skills_dashboard_replicas" {
  type        = number
  default     = 2
  description = "Number of dashboard replicas"
}

variable "skills_dashboard_host" {
  type        = string
  description = "Hostname for the skills dashboard ingress"
  default     = ""
}
