locals {
  bootstrap_realm = {
    realm                  = var.realm
    enabled                = true
    sslRequired            = "external"
    loginWithEmailAllowed  = true
    duplicateEmailsAllowed = false
    registrationAllowed    = false
    resetPasswordAllowed   = true
    rememberMe             = true
    clients = [
      {
        clientId                  = var.argocd_client_id
        name                      = "Argo CD"
        description               = "Argo CD local OIDC client"
        enabled                   = true
        protocol                  = "openid-connect"
        publicClient              = false
        secret                    = var.argocd_client_secret
        standardFlowEnabled       = true
        implicitFlowEnabled       = false
        directAccessGrantsEnabled = false
        serviceAccountsEnabled    = false
        redirectUris              = var.argocd_redirect_uris
        webOrigins                = var.argocd_web_origins
        protocolMappers = [
          {
            name            = "groups"
            protocol        = "openid-connect"
            protocolMapper  = "oidc-group-membership-mapper"
            consentRequired = false
            config = {
              "full.path"            = "false"
              "id.token.claim"       = "true"
              "access.token.claim"   = "true"
              "userinfo.token.claim" = "true"
              "claim.name"           = "groups"
            }
          }
        ]
        attributes = {
          "pkce.code.challenge.method" = "S256"
          "post.logout.redirect.uris"  = "+"
        }
      },
      {
        clientId                  = var.grafana_client_id
        name                      = "Grafana"
        description               = "Grafana local OIDC client"
        enabled                   = true
        protocol                  = "openid-connect"
        publicClient              = false
        secret                    = var.grafana_client_secret
        standardFlowEnabled       = true
        implicitFlowEnabled       = false
        directAccessGrantsEnabled = false
        serviceAccountsEnabled    = false
        redirectUris              = var.grafana_redirect_uris
        webOrigins                = var.grafana_web_origins
        protocolMappers = [
          {
            name            = "groups"
            protocol        = "openid-connect"
            protocolMapper  = "oidc-group-membership-mapper"
            consentRequired = false
            config = {
              "full.path"            = "false"
              "id.token.claim"       = "true"
              "access.token.claim"   = "true"
              "userinfo.token.claim" = "true"
              "claim.name"           = "groups"
            }
          }
        ]
        attributes = {
          "pkce.code.challenge.method" = "S256"
          "post.logout.redirect.uris"  = "+"
        }
      }
    ]
  }

  bootstrap_realm_yaml = yamlencode(local.bootstrap_realm)
}

resource "kubernetes_namespace" "keycloak" {
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

resource "helm_release" "keycloak" {
  name       = var.release_name
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "keycloak"
  version    = var.chart_version
  namespace  = kubernetes_namespace.keycloak.metadata[0].name

  set {
    name  = "auth.adminUser"
    value = var.admin_user
  }

  set_sensitive {
    name  = "auth.adminPassword"
    value = var.admin_password
  }

  set {
    name  = "production"
    value = "true"
  }

  set {
    name  = "proxyHeaders"
    value = "xforwarded"
  }

  set {
    name  = "httpEnabled"
    value = "true"
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "ingress.enabled"
    value = "false"
  }

  set {
    name  = "metrics.enabled"
    value = "true"
  }

  set {
    name  = "global.security.allowInsecureImages"
    value = "true"
  }

  set {
    name  = "image.registry"
    value = "docker.io"
  }

  set {
    name  = "image.repository"
    value = "bitnamilegacy/keycloak"
  }

  set {
    name  = "keycloakConfigCli.enabled"
    value = var.bootstrap_enabled ? "true" : "false"
  }

  set {
    name  = "keycloakConfigCli.image.registry"
    value = "docker.io"
  }

  set {
    name  = "keycloakConfigCli.image.repository"
    value = "bitnamilegacy/keycloak-config-cli"
  }

  set {
    name  = "postgresql.enabled"
    value = "true"
  }

  set {
    name  = "postgresql.image.registry"
    value = "docker.io"
  }

  set {
    name  = "postgresql.image.repository"
    value = "bitnamilegacy/postgresql"
  }

  set {
    name  = "postgresql.auth.username"
    value = var.postgresql_username
  }

  set_sensitive {
    name  = "postgresql.auth.password"
    value = var.postgresql_password
  }

  set {
    name  = "postgresql.auth.database"
    value = var.postgresql_database
  }

  set {
    name  = "postgresql.primary.persistence.enabled"
    value = "true"
  }

  set {
    name  = "postgresql.primary.persistence.storageClass"
    value = var.postgresql_storage_class
  }

  set {
    name  = "postgresql.primary.persistence.size"
    value = var.postgresql_storage_size
  }

  dynamic "set_sensitive" {
    for_each = var.bootstrap_enabled ? [1] : []
    content {
      name  = "keycloakConfigCli.configuration.realm-import\\.yaml"
      value = local.bootstrap_realm_yaml
    }
  }

  wait    = true
  timeout = 900
}

resource "kubernetes_ingress_v1" "keycloak" {
  metadata {
    name      = "keycloak"
    namespace = kubernetes_namespace.keycloak.metadata[0].name
    labels    = var.tags
    annotations = {
      "cert-manager.io/cluster-issuer" = "local-lan-ca"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.ingress_host]
      secret_name = "keycloak-tls"
    }

    rule {
      host = var.ingress_host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = var.release_name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.keycloak]
}
