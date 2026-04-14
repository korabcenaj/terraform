output "namespace" {
  description = "Namespace where ingress-nginx is deployed"
  value       = kubernetes_namespace.ingress_nginx.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.ingress_nginx.name
}

output "chart_version" {
  description = "Deployed ingress-nginx chart version"
  value       = helm_release.ingress_nginx.version
}
