variable "jellyfin_service_endpoint" {
  description = "Jellyfin service endpoint (host:port) for Sonarr integration."
  type        = string
  default     = ""

variable "qbittorrent_service_endpoint" {
  description = "qBittorrent service endpoint (host:port) for Sonarr integration."
  type        = string
  default     = ""
}
variable "namespace" {
  description = "Kubernetes namespace to deploy Sonarr."
  type        = string
}

variable "chart_version" {
  description = "Sonarr Helm chart version."
  type        = string
  default     = "16.2.2"
}

variable "persistence" {
  description = "Persistence configuration for Sonarr."
  variable "namespace" {
    description = "Kubernetes namespace to deploy Sonarr."
    type        = string
  }

  variable "chart_version" {
    description = "Sonarr Helm chart version."
    type        = string
    default     = "16.2.2"
  }

  variable "persistence" {
    description = "Persistence configuration for Sonarr."
    type        = any
    default     = {}
  }

  variable "env" {
    description = "Environment variables for Sonarr."
    type        = any
    default     = {}
  }

  variable "ingress" {
    description = "Ingress configuration for Sonarr."
    type        = any
    default     = {}
  }

  variable "resources" {
    description = "Resource requests/limits for Sonarr."
    type        = any
    default     = {}
  }

  variable "service" {
    description = "Service configuration for Sonarr."
    type        = any
    default     = {}
  }

  variable "securityContext" {
    description = "Pod security context for Sonarr."
    type        = any
    default     = {}
  }

  variable "nodeSelector" {
    description = "Node selector for Sonarr pods."
    type        = map(string)
    default     = {}
  }

  variable "affinity" {
    variable "namespace" {
      description = "Kubernetes namespace to deploy Sonarr."
      type        = string
    }

    variable "chart_version" {
      description = "Sonarr Helm chart version."
      type        = string
      default     = "16.2.2"
    }

    variable "persistence" {
      description = "Persistence configuration for Sonarr."
      type        = any
      default     = {}
    }

    variable "env" {
      description = "Environment variables for Sonarr."
      type        = any
      default     = {}
    }

    variable "ingress" {
      description = "Ingress configuration for Sonarr."
      type        = any
      default     = {}
    }

    variable "resources" {
      description = "Resource requests/limits for Sonarr."
      type        = any
      default     = {}
    }

    variable "service" {
      description = "Service configuration for Sonarr."
      type        = any
      default     = {}
    }

    variable "securityContext" {
      description = "Pod security context for Sonarr."
      type        = any
      default     = {}
    }

    variable "nodeSelector" {
      description = "Node selector for Sonarr pods."
      type        = map(string)
      default     = {}
    }

    variable "affinity" {
      variable "namespace" {
        description = "Kubernetes namespace to deploy Sonarr."
        type        = string
      }

      variable "chart_version" {
        description = "Sonarr Helm chart version."
        type        = string
        default     = "16.2.2"
      }

      variable "persistence" {
        description = "Persistence configuration for Sonarr."
        type        = any
        default     = {}
      }

      variable "env" {
        description = "Environment variables for Sonarr."
        type        = any
        default     = {}
      }

      variable "ingress" {
        description = "Ingress configuration for Sonarr."
        type        = any
        default     = {}
      }

      variable "resources" {
        description = "Resource requests/limits for Sonarr."
        type        = any
        default     = {}
      }

      variable "service" {
        description = "Service configuration for Sonarr."
        type        = any
        default     = {}
      }

      variable "securityContext" {
        description = "Pod security context for Sonarr."
        type        = any
        default     = {}
      }

      variable "nodeSelector" {
        description = "Node selector for Sonarr pods."
        type        = map(string)
        default     = {}
      }

      variable "affinity" {
        variable "namespace" {
          description = "Kubernetes namespace to deploy Sonarr."
          type        = string
        }

        variable "chart_version" {
          description = "Sonarr Helm chart version."
          type        = string
          default     = "16.2.2"
        }

        variable "persistence" {
          description = "Persistence configuration for Sonarr."
          type        = any
          default     = {}
        }

        variable "env" {
          description = "Environment variables for Sonarr."
          type        = any
          default     = {}
        }

        variable "ingress" {
          description = "Ingress configuration for Sonarr."
          type        = any
          default     = {}
        }

        variable "resources" {
          description = "Resource requests/limits for Sonarr."
          type        = any
          default     = {}
        }

        variable "service" {
          description = "Service configuration for Sonarr."
          type        = any
          default     = {}
        }

        variable "securityContext" {
          description = "Pod security context for Sonarr."
          type        = any
          default     = {}
        }

        variable "nodeSelector" {
          description = "Node selector for Sonarr pods."
          type        = map(string)
          default     = {}
        }

        variable "affinity" {
          description = "Affinity rules for Sonarr pods."
          type        = any
          default     = {}
        }

        variable "tolerations" {
          description = "Tolerations for Sonarr pods."
          type        = list(any)
          default     = []
        }

        variable "extraEnv" {
          description = "Extra environment variables for Sonarr."
          type        = list(any)
          default     = []
        }

        variable "extraVolumes" {
          description = "Extra volumes for Sonarr."
          type        = list(any)
          default     = []
        }

        variable "extraVolumeMounts" {
          description = "Extra volume mounts for Sonarr."
          type        = list(any)
          default     = []
        }

        variable "labels" {
          description = "Custom labels for Sonarr resources."
          type        = map(string)
          default     = {}
        }

        variable "annotations" {
          description = "Custom annotations for Sonarr resources."
          type        = map(string)
          default     = {}
        }

        variable "jellyfin_service_endpoint" {
          description = "Jellyfin service endpoint (host:port) for Sonarr integration."
          type        = string
          default     = ""
        }

        variable "qbittorrent_service_endpoint" {
          description = "qBittorrent service endpoint (host:port) for Sonarr integration."
          type        = string
          default     = ""
        }
