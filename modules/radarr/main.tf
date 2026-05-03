# Radarr module

resource "helm_release" "radarr" {
  name       = "radarr"
  repository = "https://k8s-at-home.com/charts/"
  chart      = "radarr"
  version    = "16.3.2"
  namespace  = var.namespace

  set {
    name  = "ingress.enabled"
    value = "true"
  }
  set {
    name  = "ingress.ingressClassName"
    value = "nginx"
  }
  set {
    name  = "ingress.hosts[0].host"
    value = "radarr.local.lan"
  }
  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }
  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "Prefix"
  }
  values = [
    yamlencode({
      persistence         = var.persistence
      env                 = var.env
      resources           = var.resources
      service             = var.service
      securityContext     = var.securityContext
      nodeSelector        = var.nodeSelector
      affinity            = var.affinity
      tolerations         = var.tolerations
      extraEnv            = concat(var.extraEnv, [
        {
          name  = "JELLYFIN_SERVICE_ENDPOINT"
          value = var.jellyfin_service_endpoint
        },
        {
          name  = "QBITTORRENT_SERVICE_ENDPOINT"
          value = var.qbittorrent_service_endpoint
        }
      ])
      extraVolumes        = var.extraVolumes
      extraVolumeMounts   = var.extraVolumeMounts
      labels              = var.labels
      annotations         = var.annotations
    })
  ]
}
