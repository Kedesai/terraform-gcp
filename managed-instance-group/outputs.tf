output "id" {
  description = "ID of the regional managed instance group manager."
  value       = google_compute_region_instance_group_manager.this.id
}

output "name" {
  description = "Name of the managed instance group manager."
  value       = google_compute_region_instance_group_manager.this.name
}

output "self_link" {
  description = "Self link of the managed instance group manager."
  value       = google_compute_region_instance_group_manager.this.self_link
}

output "instance_group" {
  description = "Self link of the underlying instance group."
  value       = google_compute_region_instance_group_manager.this.instance_group
}

output "region" {
  description = "Region where the MIG is deployed."
  value       = google_compute_region_instance_group_manager.this.region
}
