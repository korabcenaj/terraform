output "namespace" {
  description = "Gitea namespace"
  value       = kubernetes_namespace.gitea.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.gitea.name
}

output "ingress_host" {
  description = "Gitea ingress hostname"
  value       = var.ingress_host
}
