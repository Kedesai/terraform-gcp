# -----------------------------------------------------------------------------
# GKE Cluster Outputs
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "GKE cluster resource ID."
  value       = google_container_cluster.this.id
}

output "cluster_name" {
  description = "GKE cluster name."
  value       = google_container_cluster.this.name
}

output "cluster_location" {
  description = "GKE cluster region or zone."
  value       = google_container_cluster.this.location
}

output "cluster_self_link" {
  description = "GKE cluster self-link."
  value       = google_container_cluster.this.self_link
}


# -----------------------------------------------------------------------------
# Control-Plane Connection Outputs
#
# The endpoint and CA certificate are marked sensitive because they form part
# of the administrative cluster connection information.
# -----------------------------------------------------------------------------

output "cluster_endpoint" {
  description = "GKE control-plane endpoint."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded GKE cluster CA certificate."
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}


# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "network" {
  description = "VPC network used by the GKE cluster."
  value       = google_container_cluster.this.network
}

output "subnetwork" {
  description = "Subnet used by the GKE cluster."
  value       = google_container_cluster.this.subnetwork
}

output "cluster_secondary_range_name" {
  description = "Secondary IP range used for Pods."
  value       = var.cluster_secondary_range_name
}

output "services_secondary_range_name" {
  description = "Secondary IP range used for Services."
  value       = var.services_secondary_range_name
}


# -----------------------------------------------------------------------------
# Workload Identity Output
# -----------------------------------------------------------------------------

output "workload_identity_pool" {
  description = "Workload Identity Federation pool used by the GKE cluster."

  value = var.enable_workload_identity ? (
    "${var.project_id}.svc.id.goog"
  ) : null
}


# -----------------------------------------------------------------------------
# Node Pool Outputs
#
# Outputs remain keyed by the caller-defined logical node-pool identifiers.
# -----------------------------------------------------------------------------

output "node_pool_ids" {
  description = "Map of GKE node-pool resource IDs."

  value = {
    for key, pool in google_container_node_pool.this :
    key => pool.id
  }
}

output "node_pool_names" {
  description = "Map of GKE node-pool names."

  value = {
    for key, pool in google_container_node_pool.this :
    key => pool.name
  }
}

output "node_pool_instance_group_urls" {
  description = "Map of instance-group URLs created for each GKE node pool."

  value = {
    for key, pool in google_container_node_pool.this :
    key => pool.instance_group_urls
  }
}
