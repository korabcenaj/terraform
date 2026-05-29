output "argo_namespace" {
  description = "Argo Workflows namespace"
  value       = kubernetes_namespace.argo.metadata[0].name
}

output "argo_events_namespace" {
  description = "Argo Events namespace"
  value       = try(kubernetes_namespace.argo_events[0].metadata[0].name, null)
}

output "argo_rollouts_namespace" {
  description = "Argo Rollouts namespace"
  value       = try(kubernetes_namespace.argo_rollouts[0].metadata[0].name, null)
}
