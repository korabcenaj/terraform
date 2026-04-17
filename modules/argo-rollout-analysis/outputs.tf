output "template_name" {
  description = "AnalysisTemplate name"
  value       = kubernetes_manifest.portfolio_analysis_template.manifest.metadata.name
}

output "namespace" {
  description = "AnalysisTemplate namespace"
  value       = kubernetes_manifest.portfolio_analysis_template.manifest.metadata.namespace
}
