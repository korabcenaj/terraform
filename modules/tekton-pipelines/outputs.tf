output "pipelines_namespace" {
  description = "Tekton Pipelines namespace"
  value       = kubernetes_namespace.tekton_pipelines.metadata[0].name
}

output "resolvers_namespace" {
  description = "Tekton Pipelines resolvers namespace"
  value       = kubernetes_namespace.tekton_pipelines_resolvers.metadata[0].name
}
