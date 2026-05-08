locals {
  base_values = yamlencode({
    configs = {
      params = {
        # server.insecure removed — ArgoCD serves HTTPS; nginx uses backend-protocol: HTTPS
      }
    }
    repoServer = {
      livenessProbe = {
        initialDelaySeconds = 20
        timeoutSeconds      = 5
        periodSeconds       = 15
      }
      readinessProbe = {
        initialDelaySeconds = 15
        timeoutSeconds      = 5
        periodSeconds       = 10
      }
    }
  })

  oidc_values = var.oidc_enabled ? yamlencode({
    configs = {
      cm = {
        url = "https://${var.ingress_host}"
        "oidc.config" = yamlencode({
          name                     = var.oidc_name
          issuer                   = var.oidc_issuer_url
          clientID                 = var.oidc_client_id
          clientSecret             = "$argocd-oidc-secret:clientSecret"
          requestedScopes          = var.oidc_scopes
          requestedIDTokenClaims   = { groups = { essential = true } }
          enableUserInfoGroups     = true
          userInfoPath             = "/protocol/openid-connect/userinfo"
          enablePKCEAuthentication = true
          rootCA                   = trimspace(var.oidc_root_ca_pem) != "" ? var.oidc_root_ca_pem : null
        })
      }
      rbac = {
        "policy.default" = "role:admin"
        "scopes"         = "[groups, email]"
      }
    }
  }) : ""
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
    labels = merge(var.tags, {
      name                                 = var.namespace
      "pod-security.kubernetes.io/enforce" = "baseline"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].annotations]
  }
}

resource "kubernetes_secret_v1" "oidc_client_secret" {
  count = var.oidc_enabled ? 1 : 0

  metadata {
    name      = "argocd-oidc-secret"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = merge(var.tags, {
      "app.kubernetes.io/part-of" = "argocd"
    })
  }

  type = "Opaque"

  data = {
    clientSecret = var.oidc_client_secret
  }
}

resource "helm_release" "argocd" {
  name       = var.release_name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }

  dynamic "set_sensitive" {
    for_each = trimspace(var.admin_password_bcrypt) != "" ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.admin_password_bcrypt
    }
  }

  values = compact([local.base_values, local.oidc_values])

  wait    = true
  timeout = 600

  depends_on = [kubernetes_secret_v1.oidc_client_secret]
}

resource "kubernetes_ingress_v1" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer"               = "local-lan-ca"
      "nginx.ingress.kubernetes.io/ssl-passthrough"  = "false"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
      "nginx.ingress.kubernetes.io/proxy-ssl-verify" = "off"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "argocd-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "${var.release_name}-server"
              port {
                number = 443
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.argocd]
}

# ---------------------------------------------------------------------------
# Bootstrap: AppProject + Application
#
# Creates a "platform" AppProject and optionally an Application pointing at
# a Git repository. The Application is set to manual sync by default so it
# does not immediately overwrite the current state — flip auto_sync to true
# once the repo structure is validated.
# ---------------------------------------------------------------------------

resource "kubernetes_manifest" "platform_app_project" {
  count = var.create_bootstrap_app_project ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name       = var.bootstrap_project_name
      namespace  = kubernetes_namespace.argocd.metadata[0].name
      labels     = var.tags
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      description = "Platform infrastructure managed by Terraform + Argo CD"
      sourceRepos = ["*"]
      destinations = [
        {
          server    = "https://kubernetes.default.svc"
          namespace = "*"
        }
      ]
      clusterResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
      namespaceResourceWhitelist = [
        { group = "*", kind = "*" }
      ]
    }
  }

  depends_on = [helm_release.argocd]
}

resource "kubernetes_manifest" "bootstrap_application" {
  count = var.create_bootstrap_application ? 1 : 0

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = var.bootstrap_app_name
      namespace  = kubernetes_namespace.argocd.metadata[0].name
      labels     = var.tags
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = var.bootstrap_project_name
      source = {
        repoURL        = var.bootstrap_repo_url
        targetRevision = var.bootstrap_repo_revision
        path           = var.bootstrap_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.argocd.metadata[0].name
      }
      syncPolicy = var.bootstrap_auto_sync ? {
        automated   = { prune = true, selfHeal = true }
        syncOptions = ["CreateNamespace=true"]
        } : {
        automated   = null
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [kubernetes_manifest.platform_app_project]
}