output "portfolio_netpol_name" {
  description = "Portfolio NetworkPolicy name"
  value       = try(kubernetes_network_policy.portfolio[0].metadata[0].name, null)
}

output "qbittorrent_netpol_name" {
  description = "qBittorrent NetworkPolicy name"
  value       = try(kubernetes_network_policy.qbittorrent[0].metadata[0].name, null)
}

output "jellyfin_netpol_name" {
  description = "Jellyfin NetworkPolicy name"
  value       = try(kubernetes_network_policy.jellyfin[0].metadata[0].name, null)
}

output "pihole_netpol_name" {
  description = "Pi-hole NetworkPolicy name"
  value       = try(kubernetes_network_policy.pihole[0].metadata[0].name, null)
}
