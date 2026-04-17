# Sonarr module

resource "helm_release" "sonarr" {
  name       = "sonarr"
  repository = "https://charts.k8s-at-home.com/"
  chart      = "sonarr"
  version    = var.chart_version
  namespace  = var.namespace

  values = [
    yamlencode({
      persistence         = var.persistence
      env                 = var.env
      ingress             = var.ingress
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
