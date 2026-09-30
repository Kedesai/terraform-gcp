# -----------------------------------------------------------------------------
# Allocated Range Outputs
# -----------------------------------------------------------------------------

output "allocated_ip_range_id" {
  description = "Resource ID of the allocated Private Service Access range."
  value       = google_compute_global_address.this.id
}

output "allocated_ip_range_name" {
  description = "Name of the allocated Private Service Access range."
  value       = google_compute_global_address.this.name
}

output "allocated_ip_range_address" {
  description = "Starting address of the allocated Private Service Access range."
  value       = google_compute_global_address.this.address
}

output "allocated_ip_range_prefix_length" {
  description = "Prefix length of the allocated Private Service Access range."
  value       = google_compute_global_address.this.prefix_length
}

output "allocated_ip_range_self_link" {
  description = "Self-link of the allocated Private Service Access range."
  value       = google_compute_global_address.this.self_link
}


# -----------------------------------------------------------------------------
# Service Networking Connection Outputs
# -----------------------------------------------------------------------------

output "connection_network" {
  description = "VPC network used by the Service Networking connection."
  value       = google_service_networking_connection.this.network
}

output "connection_service" {
  description = "Service producer connected through Private Service Access."
  value       = google_service_networking_connection.this.service
}

output "connection_peering" {
  description = "Name of the VPC peering created by Service Networking."
  value       = google_service_networking_connection.this.peering
}

output "reserved_peering_ranges" {
  description = "Allocated range names used by the Service Networking connection."
  value       = google_service_networking_connection.this.reserved_peering_ranges
}
