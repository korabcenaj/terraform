output "namespace" {
  description = "Harbor namespace"
  value       = kubernetes_namespace.harbor.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.harbor.name
}

output "ingress_host" {
  description = "Harbor ingress hostname"
  value       = var.ingress_host
}
