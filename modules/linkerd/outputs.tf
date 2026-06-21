output "namespace" {
  description = "Linkerd namespace"
  value       = kubernetes_namespace.linkerd.metadata[0].name
}

output "viz_namespace" {
  description = "Linkerd Viz namespace"
  value       = try(kubernetes_namespace.linkerd_viz[0].metadata[0].name, null)
}
