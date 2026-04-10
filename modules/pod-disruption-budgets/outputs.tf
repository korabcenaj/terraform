output "portfolio_pdb_name" {
  description = "Portfolio PodDisruptionBudget name"
  value       = try(kubernetes_pod_disruption_budget_v1.portfolio[0].metadata[0].name, null)
}

output "qbittorrent_pdb_name" {
  description = "qBittorrent PodDisruptionBudget name"
  value       = try(kubernetes_pod_disruption_budget_v1.qbittorrent[0].metadata[0].name, null)
}

output "jellyfin_pdb_name" {
  description = "Jellyfin PodDisruptionBudget name"
  value       = try(kubernetes_pod_disruption_budget_v1.jellyfin[0].metadata[0].name, null)
}

output "pihole_pdb_name" {
  description = "Pi-hole PodDisruptionBudget name"
  value       = try(kubernetes_pod_disruption_budget_v1.pihole[0].metadata[0].name, null)
}
