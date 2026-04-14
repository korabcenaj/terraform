output "namespace" {
  description = "Namespace where Argo CD is deployed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.argocd.name
}

output "chart_version" {
  description = "Deployed Argo CD chart version"
  value       = helm_release.argocd.version
}

output "server_service_name" {
  description = "Argo CD API server service name"
  value       = "${helm_release.argocd.name}-server"
}

output "ingress_host" {
  description = "Argo CD server ingress hostname"
  value       = var.ingress_host
}