# -----------------------------------------------------------------------------
# Google Kubernetes Engine Cluster
#
# This module creates a GKE cluster and separately managed node pools.
#
# It intentionally does not create:
#
# - GCP projects
# - VPC networks
# - Subnets or secondary IP ranges
# - Cloud Router or Cloud NAT
# - Service accounts
# - IAM role assignments
# - KMS keys or KMS IAM
# - Artifact Registry repositories
# - Kubernetes workloads
#
# Those responsibilities belong to separate reusable modules or orchestration
# layers such as the future GCP Landing Zone.
# -----------------------------------------------------------------------------

resource "google_container_cluster" "this" {
  project = var.project_id

  # ---------------------------------------------------------------------------
  # Cluster Identity and Location
  # ---------------------------------------------------------------------------

  name        = var.cluster_name
  location    = var.location
  description = var.description

  resource_labels = var.resource_labels

  deletion_protection = var.deletion_protection


  # ---------------------------------------------------------------------------
  # Separately Managed Node Pools
  #
  # GKE requires a node pool during cluster creation. This configuration creates
  # the smallest temporary default pool and immediately removes it.
  #
  # All persistent node pools are managed using google_container_node_pool
  # resources below.
  # ---------------------------------------------------------------------------

  remove_default_node_pool = true
  initial_node_count       = 1


  # ---------------------------------------------------------------------------
  # Existing Network and Subnet
  #
  # These identifiers are supplied by the caller and should normally come from
  # the VPC/foundation layer.
  # ---------------------------------------------------------------------------

  network    = var.network
  subnetwork = var.subnetwork

  networking_mode = upper(var.networking_mode)


  # ---------------------------------------------------------------------------
  # VPC-Native IP Allocation
  #
  # This block is generated only when VPC_NATIVE networking is selected.
  #
  # The Pod and Service range names must already exist as secondary ranges on
  # the selected subnet.
  # ---------------------------------------------------------------------------

  dynamic "ip_allocation_policy" {
    for_each = upper(var.networking_mode) == "VPC_NATIVE" ? [1] : []

    content {
      cluster_secondary_range_name  = var.cluster_secondary_range_name
      services_secondary_range_name = var.services_secondary_range_name
    }
  }


  # ---------------------------------------------------------------------------
  # Private Cluster Configuration
  #
  # Private nodes do not receive external IP addresses.
  #
  # The control-plane endpoint can remain publicly reachable with authorized
  # networks, or can be made private through enable_private_endpoint.
  # ---------------------------------------------------------------------------

  private_cluster_config {
    enable_private_nodes    = var.enable_private_nodes
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = var.master_global_access_enabled
    }
  }


  # ---------------------------------------------------------------------------
  # Control-Plane Authorized Networks
  #
  # The block is generated only when one or more CIDR entries are supplied.
  # ---------------------------------------------------------------------------

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []

    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks

        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }


  # ---------------------------------------------------------------------------
  # Release Channel
  # ---------------------------------------------------------------------------

  release_channel {
    channel = upper(var.release_channel)
  }


  # ---------------------------------------------------------------------------
  # Workload Identity Federation for GKE
  #
  # The workload pool follows the standard GKE project naming format.
  #
  # Kubernetes service-account IAM bindings remain outside this module.
  # ---------------------------------------------------------------------------

  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []

    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }


  # ---------------------------------------------------------------------------
  # Cluster Security
  # ---------------------------------------------------------------------------

  enable_shielded_nodes       = var.enable_shielded_nodes
  enable_intranode_visibility = var.enable_intranode_visibility


  # ---------------------------------------------------------------------------
  # Network Policy
  #
  # This enables the cluster-level network-policy capability.
  # Kubernetes NetworkPolicy objects must still be deployed separately.
  # ---------------------------------------------------------------------------

  network_policy {
    enabled  = var.enable_network_policy
    provider = "CALICO"
  }


  # ---------------------------------------------------------------------------
  # Logging and Monitoring
  # ---------------------------------------------------------------------------

  logging_service    = var.logging_service
  monitoring_service = var.monitoring_service


  # ---------------------------------------------------------------------------
  # Kubernetes Secret Encryption
  #
  # When a KMS key is provided, GKE application-layer database encryption is
  # configured with the supplied key.
  #
  # Required KMS IAM permissions must be configured outside this module.
  # ---------------------------------------------------------------------------

  dynamic "database_encryption" {
    for_each = var.database_encryption_key_id == null ? [] : [1]

    content {
      state    = "ENCRYPTED"
      key_name = var.database_encryption_key_id
    }
  }


  # ---------------------------------------------------------------------------
  # Recurring Maintenance Window
  #
  # The block is generated only when all recurring-window values are supplied.
  # ---------------------------------------------------------------------------

  dynamic "maintenance_policy" {
    for_each = (
      var.maintenance_start_time != null &&
      var.maintenance_end_time != null &&
      var.maintenance_recurrence != null
    ) ? [1] : []

    content {
      recurring_window {
        start_time = var.maintenance_start_time
        end_time   = var.maintenance_end_time
        recurrence = var.maintenance_recurrence
      }
    }
  }
}


# -----------------------------------------------------------------------------
# Separately Managed GKE Node Pools
#
# Each entry in var.node_pools creates one google_container_node_pool.
#
# Separating node pools from the cluster allows their lifecycle and
# configuration to be managed independently from the cluster resource.
# -----------------------------------------------------------------------------

resource "google_container_node_pool" "this" {
  for_each = var.node_pools

  project = var.project_id

  name     = each.value.name
  location = var.location
  cluster  = google_container_cluster.this.name

  node_locations = each.value.node_locations

  initial_node_count = each.value.initial_node_count


  # ---------------------------------------------------------------------------
  # Node Pool Autoscaling
  #
  # The autoscaling block is generated only when autoscaling is enabled.
  # ---------------------------------------------------------------------------

  dynamic "autoscaling" {
    for_each = each.value.autoscaling.enabled ? [1] : []

    content {
      min_node_count = each.value.autoscaling.min_count
      max_node_count = each.value.autoscaling.max_count
    }
  }


  # ---------------------------------------------------------------------------
  # Node Pool Management
  # ---------------------------------------------------------------------------

  management {
    auto_repair  = each.value.auto_repair
    auto_upgrade = each.value.auto_upgrade
  }


  # ---------------------------------------------------------------------------
  # Node Pool Upgrade Strategy
  # ---------------------------------------------------------------------------

  upgrade_settings {
    max_surge       = each.value.max_surge
    max_unavailable = each.value.max_unavailable
  }


  # ---------------------------------------------------------------------------
  # Node Configuration
  #
  # The service account is optional. For platform deployments, callers should
  # normally supply a dedicated node service-account email.
  # ---------------------------------------------------------------------------

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    image_type   = each.value.image_type

    service_account = each.value.service_account_email
    oauth_scopes    = each.value.oauth_scopes

    labels   = each.value.labels
    metadata = each.value.metadata
    tags     = each.value.tags

    spot = each.value.spot


    # -------------------------------------------------------------------------
    # Shielded Node Configuration
    # -------------------------------------------------------------------------

    shielded_instance_config {
      enable_secure_boot = (
        each.value.enable_secure_boot
      )

      enable_integrity_monitoring = (
        each.value.enable_integrity_monitoring
      )
    }


    # -------------------------------------------------------------------------
    # Kubernetes Node Taints
    #
    # Taints are optional and generated from the supplied list.
    # -------------------------------------------------------------------------

    dynamic "taint" {
      for_each = each.value.taints

      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = upper(taint.value.effect)
      }
    }
  }


  # ---------------------------------------------------------------------------
  # Node Pool Lifecycle
  #
  # Node pools depend on the cluster and are managed independently.
  # ---------------------------------------------------------------------------

  depends_on = [
    google_container_cluster.this
  ]
}
