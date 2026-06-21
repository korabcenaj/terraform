################################################################################
# Terraform Import Blocks (Terraform 1.5+)
# Import cluster resources that already exist so Terraform manages them
################################################################################

# Namespaces
import {
  to = module.cert_manager[0].kubernetes_namespace.cert_manager
  id = "cert-manager"
}

import {
  to = module.keda[0].kubernetes_namespace.keda
  id = "keda"
}

import {
  to = module.traefik[0].kubernetes_namespace.traefik
  id = "traefik"
}

import {
  to = module.tempo[0].kubernetes_namespace.tracing
  id = "tracing"
}

import {
  to = kubernetes_namespace.portfolio[0]
  id = "portfolio"
}

import {
  to = kubernetes_namespace.jellyfin[0]
  id = "jellyfin"
}

import {
  to = kubernetes_namespace.pihole[0]
  id = "pihole"
}

import {
  to = kubernetes_namespace.ci_builds
  id = "ci-builds"
}

# Helm releases
import {
  to = module.cert_manager[0].helm_release.cert_manager[0]
  id = "cert-manager/cert-manager"
}

import {
  to = module.keda[0].helm_release.keda
  id = "keda/keda"
}

import {
  to = module.traefik[0].helm_release.traefik
  id = "traefik/traefik"
}

import {
  to = module.tempo[0].helm_release.tempo
  id = "tracing/tempo"
}

import {
  to = module.oauth2_proxy[0].helm_release.oauth2_proxy
  id = "oauth2-proxy/oauth2-proxy"
}


