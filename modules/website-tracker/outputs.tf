output "namespace" {
  description = "Website Tracker namespace"
  value       = kubernetes_namespace.website_tracker.metadata[0].name
}
