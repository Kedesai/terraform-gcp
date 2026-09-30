# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where the GKE cluster is created."
  type        = string
}


# -----------------------------------------------------------------------------
# GKE Cluster Configuration
#
# location can be either:
#
# - A region for a regional cluster, such as us-central1
# - A zone for a zonal cluster, such as us-central1-a
#
# The caller determines whether the cluster is regional or zonal through the
# supplied location value.
# -----------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "location" {
  description = "Region or zone where the GKE cluster is created."
  type        = string
}

variable "description" {
  description = "Optional description of the GKE cluster."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection for the GKE cluster."
  type        = bool
  default     = true
}

variable "resource_labels" {
  description = "Labels applied to the GKE cluster."
  type        = map(string)

  default = {
    managed_by = "terraform"
  }
}


# -----------------------------------------------------------------------------
# GKE Networking
#
# The GKE module does not create a VPC or subnet.
#
# network and subnetwork should normally consume outputs from the reusable VPC
# module or from a foundation workspace.
# -----------------------------------------------------------------------------

variable "network" {
  description = "Existing VPC network name, ID, or self-link used by the cluster."
  type        = string
}

variable "subnetwork" {
  description = "Existing subnet name, ID, or self-link used by the cluster."
  type        = string
}

variable "networking_mode" {
  description = "GKE networking mode."
  type        = string
  default     = "VPC_NATIVE"

  validation {
    condition = contains(
      ["VPC_NATIVE", "ROUTES"],
      upper(var.networking_mode)
    )

    error_message = "networking_mode must be VPC_NATIVE or ROUTES."
  }
}


# -----------------------------------------------------------------------------
# VPC-Native Pod and Service Ranges
#
# The range names must refer to secondary IP ranges configured on the selected
# subnet.
#
# These values are required when using named secondary ranges with a
# VPC-native cluster.
# -----------------------------------------------------------------------------

variable "cluster_secondary_range_name" {
  description = "Subnet secondary range name used for Kubernetes Pods."
  type        = string
  default     = null
}

variable "services_secondary_range_name" {
  description = "Subnet secondary range name used for Kubernetes Services."
  type        = string
  default     = null
}


# -----------------------------------------------------------------------------
# Private Cluster Configuration
#
# enable_private_nodes prevents nodes from receiving external IP addresses.
#
# enable_private_endpoint controls whether the Kubernetes control-plane
# endpoint is accessible only through its private address.
#
# master_ipv4_cidr_block is used for communication between the VPC and private
# GKE control plane.
# -----------------------------------------------------------------------------

variable "enable_private_nodes" {
  description = "Create GKE nodes with private IP addresses only."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Expose only the private GKE control-plane endpoint."
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR range used by the private GKE control plane."
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_global_access_enabled" {
  description = "Allow access to the private control-plane endpoint from any Google Cloud region."
  type        = bool
  default     = false
}


# -----------------------------------------------------------------------------
# Control-Plane Authorized Networks
#
# When empty, no master_authorized_networks_config block is generated.
#
# Each entry supplies a CIDR block and an optional display name.
# -----------------------------------------------------------------------------

variable "master_authorized_networks" {
  description = "CIDR blocks authorized to access the GKE control-plane endpoint."

  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))

  default = []
}


# -----------------------------------------------------------------------------
# Release Channel
#
# Supported release channels exposed by this module:
#
# - RAPID
# - REGULAR
# - STABLE
# - EXTENDED
# - UNSPECIFIED
# -----------------------------------------------------------------------------

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"

  validation {
    condition = contains(
      ["RAPID", "REGULAR", "STABLE", "EXTENDED", "UNSPECIFIED"],
      upper(var.release_channel)
    )

    error_message = "release_channel must be RAPID, REGULAR, STABLE, EXTENDED, or UNSPECIFIED."
  }
}


# -----------------------------------------------------------------------------
# Workload Identity Federation for GKE
#
# When enabled, the cluster uses the workload pool:
#
#   PROJECT_ID.svc.id.goog
#
# Kubernetes-to-Google service-account IAM bindings remain outside this module.
# -----------------------------------------------------------------------------

variable "enable_workload_identity" {
  description = "Enable Workload Identity Federation for GKE."
  type        = bool
  default     = true
}


# -----------------------------------------------------------------------------
# Cluster Security Configuration
# -----------------------------------------------------------------------------

variable "enable_shielded_nodes" {
  description = "Enable Shielded GKE nodes."
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable GKE network policy."
  type        = bool
  default     = true
}

variable "enable_intranode_visibility" {
  description = "Enable visibility for traffic between Pods on the same node."
  type        = bool
  default     = false
}


# -----------------------------------------------------------------------------
# Logging and Monitoring
# -----------------------------------------------------------------------------

variable "logging_service" {
  description = "Logging service used by the GKE cluster."
  type        = string
  default     = "logging.googleapis.com/kubernetes"
}

variable "monitoring_service" {
  description = "Monitoring service used by the GKE cluster."
  type        = string
  default     = "monitoring.googleapis.com/kubernetes"
}


# -----------------------------------------------------------------------------
# Secret Encryption with Cloud KMS
#
# database_encryption_key_id is an optional fully qualified Cloud KMS Crypto
# Key ID used to encrypt Kubernetes secrets in the GKE application layer.
#
# Required key permissions must be configured outside this module.
# -----------------------------------------------------------------------------

variable "database_encryption_key_id" {
  description = "Optional Cloud KMS Crypto Key ID used for GKE database encryption."
  type        = string
  default     = null
}


# -----------------------------------------------------------------------------
# Maintenance Window
#
# maintenance_start_time uses RFC 3339 time format.
#
# maintenance_recurrence uses RFC 5545 recurrence syntax.
#
# When start time and recurrence are both null, the recurring maintenance block
# is omitted.
# -----------------------------------------------------------------------------

variable "maintenance_start_time" {
  description = "Optional RFC 3339 start time for the recurring maintenance window."
  type        = string
  default     = null
}

variable "maintenance_end_time" {
  description = "Optional RFC 3339 end time for the recurring maintenance window."
  type        = string
  default     = null
}

variable "maintenance_recurrence" {
  description = "Optional RFC 5545 recurrence rule for the maintenance window."
  type        = string
  default     = null
}


# -----------------------------------------------------------------------------
# GKE Node Pools
#
# Node pools are managed independently from the cluster resource.
#
# The logical map key is used by Terraform. The actual node-pool name is
# supplied through the name property.
# -----------------------------------------------------------------------------

variable "node_pools" {
  description = "Map of separately managed GKE node pools."

  type = map(object({
    # -------------------------------------------------------------------------
    # Node Pool Identity and Placement
    # -------------------------------------------------------------------------

    name           = string
    node_locations = optional(list(string))

    # -------------------------------------------------------------------------
    # Node Pool Size and Autoscaling
    #
    # initial_node_count is the initial number of nodes per zone.
    #
    # When autoscaling is enabled, min_count and max_count control the size.
    # -------------------------------------------------------------------------

    initial_node_count = optional(number, 1)

    autoscaling = optional(object({
      enabled   = optional(bool, true)
      min_count = optional(number, 1)
      max_count = optional(number, 3)
    }), {})

    # -------------------------------------------------------------------------
    # Node Pool Management
    # -------------------------------------------------------------------------

    auto_repair  = optional(bool, true)
    auto_upgrade = optional(bool, true)

    max_surge       = optional(number, 1)
    max_unavailable = optional(number, 0)

    # -------------------------------------------------------------------------
    # Node Compute Configuration
    # -------------------------------------------------------------------------

    machine_type = optional(string, "e2-standard-2")
    disk_size_gb = optional(number, 100)
    disk_type    = optional(string, "pd-balanced")
    image_type   = optional(string, "COS_CONTAINERD")

    service_account_email = optional(string)

    oauth_scopes = optional(list(string), [
      "https://www.googleapis.com/auth/cloud-platform"
    ])

    # -------------------------------------------------------------------------
    # Node Metadata, Labels, Tags, and Taints
    # -------------------------------------------------------------------------

    labels   = optional(map(string), {})
    metadata = optional(map(string), {})
    tags     = optional(list(string), [])

    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])

    # -------------------------------------------------------------------------
    # Node Security
    # -------------------------------------------------------------------------

    enable_secure_boot          = optional(bool, false)
    enable_integrity_monitoring = optional(bool, true)

    # -------------------------------------------------------------------------
    # Node Provisioning Model
    #
    # spot enables Spot VMs for the node pool.
    # -------------------------------------------------------------------------

    spot = optional(bool, false)
  }))

  default = {}


  # ---------------------------------------------------------------------------
  # Initial Node Count Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for pool in values(var.node_pools) :
      pool.initial_node_count > 0
    ])

    error_message = "Every node pool initial_node_count must be greater than zero."
  }


  # ---------------------------------------------------------------------------
  # Autoscaling Range Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for pool in values(var.node_pools) :
      pool.autoscaling.enabled == false ||
      (
        pool.autoscaling.min_count >= 0 &&
        pool.autoscaling.max_count >= pool.autoscaling.min_count
      )
    ])

    error_message = "For autoscaled node pools, max_count must be greater than or equal to min_count."
  }


  # ---------------------------------------------------------------------------
  # Node Disk Size Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for pool in values(var.node_pools) :
      pool.disk_size_gb > 0
    ])

    error_message = "Every node-pool disk_size_gb value must be greater than zero."
  }


  # ---------------------------------------------------------------------------
  # Taint Effect Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue(flatten([
      for pool in values(var.node_pools) : [
        for taint in pool.taints :
        contains(
          ["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"],
          upper(taint.effect)
        )
      ]
    ]))

    error_message = "Node taint effect must be NO_SCHEDULE, PREFER_NO_SCHEDULE, or NO_EXECUTE."
  }
}
