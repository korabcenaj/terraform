output "namespace" {
  description = "Website Tracker namespace"
  value       = kubernetes_namespace.website_tracker.metadata[0].name
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.website_tracker.name
}
