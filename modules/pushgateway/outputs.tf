output "namespace" {
  description = "Namespace where Pushgateway is deployed."
  value       = helm_release.pushgateway.namespace
}

output "release_name" {
  description = "Helm release name."
  value       = helm_release.pushgateway.name
}

output "chart_version" {
  description = "Deployed chart version."
  value       = helm_release.pushgateway.version
}
