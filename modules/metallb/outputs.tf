output "namespace" {
  description = "Namespace where MetalLB is deployed."
  value       = kubernetes_namespace.metallb.metadata[0].name
}

output "release_name" {
  description = "Helm release name."
  value       = helm_release.metallb.name
}

output "chart_version" {
  description = "Deployed chart version."
  value       = helm_release.metallb.version
}

output "ip_pool_name" {
  description = "Name of the IPAddressPool."
  value       = var.ip_pool_name
}
