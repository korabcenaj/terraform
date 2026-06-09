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
  description = "Traefik Middleware reference for forward-auth on protected ingresses (use with traefik.ingress.kubernetes.io/router.middlewares annotation)"
  value       = "${kubernetes_namespace.oauth2_proxy.metadata[0].name}-forward-auth@kubernetescrd"
}

output "signin_url" {
  description = "OAuth2 Proxy sign-in URL for redirecting unauthenticated users"
  value       = "https://${var.ingress_host}/oauth2/start?rd=$escaped_request_uri"
}

output "middleware_name" {
  description = "Traefik ForwardAuth Middleware resource name"
  value       = "forward-auth"
}
