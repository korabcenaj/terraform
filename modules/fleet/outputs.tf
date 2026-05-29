output "release_name" {
  description = "Fleet Helm release name"
  value       = helm_release.fleet.name
}
