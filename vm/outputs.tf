# -----------------------------------------------------------------------------
# VM Identity Outputs
#
# Outputs are keyed by the logical identifiers supplied through var.instances.
# -----------------------------------------------------------------------------

output "instance_ids" {
  description = "Map of Compute Engine VM instance IDs."

  value = {
    for key, instance in google_compute_instance.this :
    key => instance.instance_id
  }
}


output "instance_names" {
  description = "Map of Compute Engine VM instance names."

  value = {
    for key, instance in google_compute_instance.this :
    key => instance.name
  }
}


output "instance_self_links" {
  description = "Map of Compute Engine VM instance self-links."

  value = {
    for key, instance in google_compute_instance.this :
    key => instance.self_link
  }
}


output "instance_zones" {
  description = "Map of Compute Engine VM instance zones."

  value = {
    for key, instance in google_compute_instance.this :
    key => instance.zone
  }
}


# -----------------------------------------------------------------------------
# VM Network Outputs
#
# Exposes internal and external addresses without requiring callers to inspect
# the nested network-interface attributes.
#
# external_ip_addresses returns null for VMs without an external address.
# -----------------------------------------------------------------------------

output "internal_ip_addresses" {
  description = "Map of VM internal IPv4 addresses."

  value = {
    for key, instance in google_compute_instance.this :
    key => instance.network_interface[0].network_ip
  }
}


output "external_ip_addresses" {
  description = "Map of VM external IPv4 addresses."

  value = {
    for key, instance in google_compute_instance.this :
    key => try(
      instance.network_interface[0].access_config[0].nat_ip,
      null
    )
  }
}


# -----------------------------------------------------------------------------
# Boot Disk Outputs
# -----------------------------------------------------------------------------

output "boot_disk_sources" {
  description = "Map of VM boot disk source references."

  value = {
    for key, instance in google_compute_instance.this :
    key => instance.boot_disk[0].source
  }
}
