output "network_id" {
  description = "ID of the VPC network."
  value       = local.network_id
}

output "network_name" {
  description = "Name of the VPC network."
  value       = local.network_name
}

output "network_self_link" {
  description = "Self link of the VPC network."
  value       = local.network_self_link
}

output "subnet_ids" {
  description = "Map of subnet IDs keyed by the caller-defined subnet key."

  value = {
    for key, subnet in google_compute_subnetwork.this :
    key => subnet.id
  }
}

output "subnet_names" {
  description = "Map of subnet names keyed by the caller-defined subnet key."

  value = {
    for key, subnet in google_compute_subnetwork.this :
    key => subnet.name
  }
}

output "subnet_self_links" {
  description = "Map of subnet self-links keyed by the caller-defined subnet key."

  value = {
    for key, subnet in google_compute_subnetwork.this :
    key => subnet.self_link
  }
}

output "subnet_cidr_ranges" {
  description = "Map of subnet primary CIDR ranges."

  value = {
    for key, subnet in google_compute_subnetwork.this :
    key => subnet.ip_cidr_range
  }
}

output "subnet_secondary_ranges" {
  description = "Secondary IP ranges associated with each created subnet."

  value = {
    for key, subnet in google_compute_subnetwork.this :
    key => subnet.secondary_ip_range
  }
}
