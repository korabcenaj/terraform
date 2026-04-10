output "portfolio_quota_name" {
  description = "Portfolio ResourceQuota name"
  value       = try(kubernetes_resource_quota.portfolio[0].metadata[0].name, null)
}

output "qbittorrent_quota_name" {
  description = "qBittorrent ResourceQuota name"
  value       = try(kubernetes_resource_quota.qbittorrent[0].metadata[0].name, null)
}

output "jellyfin_quota_name" {
  description = "Jellyfin ResourceQuota name"
  value       = try(kubernetes_resource_quota.jellyfin[0].metadata[0].name, null)
}

output "pihole_quota_name" {
  description = "Pi-hole ResourceQuota name"
  value       = try(kubernetes_resource_quota.pihole[0].metadata[0].name, null)
}
