output "namespace" {
  description = "OAuth2 Proxy namespace"
  value       = kubernetes_namespace.oauth2_proxy.metadata[0].name
}

output "release_name" {
  description = "OAuth2 Proxy Helm release name"
  value       = helm_release.oauth2_proxy.name
}

output "chart_version" {
  description = "Deployed chart version"
  value       = helm_release.oauth2_proxy.version
}

output "ingress_host" {
  description = "OAuth2 Proxy ingress hostname"
  value       = var.ingress_host
}

output "auth_url" {
  description = "Value for nginx.ingress.kubernetes.io/auth-url annotation on protected ingresses"
  value       = "https://${var.ingress_host}/oauth2/auth"
}

output "signin_url" {
  description = "Value for nginx.ingress.kubernetes.io/auth-signin annotation on protected ingresses"
  value       = "https://${var.ingress_host}/oauth2/start?rd=$escaped_request_uri"
}
