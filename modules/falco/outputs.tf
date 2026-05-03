output "namespace" {
  description = "Namespace where Falco is deployed."
  value       = kubernetes_namespace.falco.metadata[0].name
}

output "release_name" {
  description = "Helm release name."
  value       = helm_release.falco.name
}

output "chart_version" {
  description = "Deployed chart version."
  value       = helm_release.falco.version
}
