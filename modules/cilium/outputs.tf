output "release_name" {
  description = "Cilium Helm release name"
  value       = helm_release.cilium.name
}

output "namespace" {
  description = "Cilium namespace"
  value       = helm_release.cilium.namespace
}
