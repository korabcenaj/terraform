resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name = var.namespace
      # cert-manager webhook requires this label to exempt its own namespace
      "cert-manager.io/disable-validation" = "true"
    })
  }
}

resource "helm_release" "cert_manager" {
  count = var.manage_controller_install ? 1 : 0

  name       = var.release_name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  # Install CRDs as part of the Helm release (safe for single-cluster use)
  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "replicaCount"
    value = tostring(var.replicas)
  }

  # Enable leader election so multiple replicas don't conflict
  set {
    name  = "extraArgs[0]"
    value = "--leader-elect=true"
  }

  wait    = true
  timeout = 300
}

# Bootstrap self-signed ClusterIssuer — issues the local-lan CA certificate
resource "kubernetes_manifest" "selfsigned_issuer" {
  count = var.create_selfsigned_issuer ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name   = "selfsigned-bootstrap"
      labels = var.tags
    }
    spec = {
      selfSigned = {}
    }
  }

  depends_on = [helm_release.cert_manager]
}

# local-lan CA certificate — signed by the selfsigned-bootstrap issuer
resource "kubernetes_manifest" "local_lan_ca_cert" {
  count = var.create_local_ca_issuer ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "local-lan-ca"
      namespace = kubernetes_namespace.cert_manager.metadata[0].name
      labels    = var.tags
    }
    spec = {
      isCA       = true
      commonName = "local.lan CA"
      subject = {
        organizations = ["home-lab"]
      }
      secretName = "local-lan-ca-secret"
      privateKey = {
        algorithm = "ECDSA"
        size      = 256
      }
      issuerRef = {
        name  = "selfsigned-bootstrap"
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
      duration    = "43800h" # 5 years
      renewBefore = "720h"   # 30 days
    }
  }

  depends_on = [kubernetes_manifest.selfsigned_issuer]
}

# local-lan-ca ClusterIssuer — used by all app ingresses
resource "kubernetes_manifest" "local_lan_ca_issuer" {
  count = var.create_local_ca_issuer ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name   = "local-lan-ca"
      labels = var.tags
    }
    spec = {
      ca = {
        secretName = "local-lan-ca-secret"
      }
    }
  }

  depends_on = [kubernetes_manifest.local_lan_ca_cert]
}
