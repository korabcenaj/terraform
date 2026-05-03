output "namespace" {
  description = "Namespace where the Caddy Ingress Controller is deployed"
  value       = kubernetes_namespace.caddy.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.caddy.name
}

output "chart_version" {
  description = "Deployed Caddy Ingress Controller chart version"
  value       = helm_release.caddy.version
}

output "ingress_class_name" {
  description = "IngressClass name registered by this Caddy controller"
  value       = var.ingress_class_name
}
