output "namespace" {
  description = "MetalLB namespace"
  value       = kubernetes_namespace.metallb.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.metallb.name
}
