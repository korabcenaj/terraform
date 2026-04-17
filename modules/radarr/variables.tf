variable "jellyfin_service_endpoint" {
  description = "Jellyfin service endpoint (host:port) for Radarr integration."
  type        = string
  default     = ""

variable "qbittorrent_service_endpoint" {
  description = "qBittorrent service endpoint (host:port) for Radarr integration."
  type        = string
  default     = ""
}
variable "namespace" {
  description = "Kubernetes namespace to deploy Radarr."
  type        = string
}

variable "chart_version" {
  description = "Radarr Helm chart version."
  type        = string
  default     = "16.2.2"
}

variable "persistence" {
  description = "Persistence configuration for Radarr."
  variable "namespace" {
    description = "Kubernetes namespace to deploy Radarr."
    type        = string
  }

  variable "chart_version" {
    description = "Radarr Helm chart version."
    type        = string
    default     = "16.2.2"
  }

  variable "persistence" {
    description = "Persistence configuration for Radarr."
    type        = any
    default     = {}
  }

  variable "env" {
    description = "Environment variables for Radarr."
    type        = any
    default     = {}
  }

  variable "ingress" {
    description = "Ingress configuration for Radarr."
    type        = any
    default     = {}
  }

  variable "resources" {
    description = "Resource requests/limits for Radarr."
    type        = any
    default     = {}
  }

  variable "service" {
    description = "Service configuration for Radarr."
    type        = any
    default     = {}
  }

  variable "securityContext" {
    description = "Pod security context for Radarr."
    type        = any
    default     = {}
  }

  variable "nodeSelector" {
    description = "Node selector for Radarr pods."
    type        = map(string)
    default     = {}
  }

  variable "affinity" {
    variable "namespace" {
      description = "Kubernetes namespace to deploy Radarr."
      type        = string
    }

    variable "chart_version" {
      description = "Radarr Helm chart version."
      type        = string
      default     = "16.2.2"
    }

    variable "persistence" {
      description = "Persistence configuration for Radarr."
      type        = any
      default     = {}
    }

    variable "env" {
      description = "Environment variables for Radarr."
      type        = any
      default     = {}
    }

    variable "ingress" {
      description = "Ingress configuration for Radarr."
      type        = any
      default     = {}
    }

    variable "resources" {
      description = "Resource requests/limits for Radarr."
      type        = any
      default     = {}
    }

    variable "service" {
      description = "Service configuration for Radarr."
      type        = any
      default     = {}
    }

    variable "securityContext" {
      description = "Pod security context for Radarr."
      type        = any
      default     = {}
    }

    variable "nodeSelector" {
      description = "Node selector for Radarr pods."
      type        = map(string)
      default     = {}
    }

    variable "affinity" {
      variable "namespace" {
        description = "Kubernetes namespace to deploy Radarr."
        type        = string
      }

      variable "chart_version" {
        description = "Radarr Helm chart version."
        type        = string
        default     = "16.2.2"
      }

      variable "persistence" {
        description = "Persistence configuration for Radarr."
        type        = any
        default     = {}
      }

      variable "env" {
        description = "Environment variables for Radarr."
        type        = any
        default     = {}
      }

      variable "ingress" {
        description = "Ingress configuration for Radarr."
        type        = any
        default     = {}
      }

      variable "resources" {
        description = "Resource requests/limits for Radarr."
        type        = any
        default     = {}
      }

      variable "service" {
        description = "Service configuration for Radarr."
        type        = any
        default     = {}
      }

      variable "securityContext" {
        description = "Pod security context for Radarr."
        type        = any
        default     = {}
      }

      variable "nodeSelector" {
        description = "Node selector for Radarr pods."
        type        = map(string)
        default     = {}
      }

      variable "affinity" {
        description = "Affinity rules for Radarr pods."
        type        = any
        default     = {}
      }

      variable "tolerations" {
        description = "Tolerations for Radarr pods."
        type        = list(any)
        default     = []
      }

      variable "extraEnv" {
        description = "Extra environment variables for Radarr."
        type        = list(any)
        default     = []
      }

      variable "extraVolumes" {
        description = "Extra volumes for Radarr."
        type        = list(any)
        default     = []
      }

      variable "extraVolumeMounts" {
        description = "Extra volume mounts for Radarr."
        type        = list(any)
        default     = []
      }

      variable "labels" {
        description = "Custom labels for Radarr resources."
        type        = map(string)
        default     = {}
      }

      variable "annotations" {
        description = "Custom annotations for Radarr resources."
        type        = map(string)
        default     = {}
      }

      variable "jellyfin_service_endpoint" {
        description = "Jellyfin service endpoint (host:port) for Radarr integration."
        type        = string
        default     = ""
      }

      variable "qbittorrent_service_endpoint" {
        description = "qBittorrent service endpoint (host:port) for Radarr integration."
        type        = string
        default     = ""
      }
