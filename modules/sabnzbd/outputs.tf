output "namespace" {
  description = "Sabnzbd namespace"
  value       = kubernetes_namespace.sabnzbd.metadata[0].name
}
