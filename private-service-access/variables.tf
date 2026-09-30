# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project containing the VPC and Private Service Access resources."
  type        = string

  validation {
    condition     = trimspace(var.project_id) != ""
    error_message = "project_id must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Existing VPC Network
#
# This module does not create the VPC network.
#
# network_id is used by:
#
# - The allocated global address
# - The Service Networking connection
#
# network_name is used by the optional peering route configuration.
# -----------------------------------------------------------------------------

variable "network_id" {
  description = "ID or self-link of the existing VPC network."
  type        = string

  validation {
    condition     = trimspace(var.network_id) != ""
    error_message = "network_id must not be empty."
  }
}

variable "network_name" {
  description = "Name of the existing VPC network."
  type        = string

  validation {
    condition     = trimspace(var.network_name) != ""
    error_message = "network_name must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Reserved Private Service Access Range
#
# Private Service Access requires an INTERNAL global address with:
#
# purpose      = "VPC_PEERING"
# address_type = "INTERNAL"
#
# Allocation patterns:
#
# Automatic allocation:
#   Supply prefix_length and leave address null.
#
# Explicit allocation:
#   Supply both address and prefix_length.
# -----------------------------------------------------------------------------

variable "allocated_range_name" {
  description = "Name of the allocated Private Service Access range."
  type        = string

  validation {
    condition     = trimspace(var.allocated_range_name) != ""
    error_message = "allocated_range_name must not be empty."
  }
}

variable "allocated_range_description" {
  description = "Description of the allocated Private Service Access range."
  type        = string
  default     = "Private Service Access range managed by Terraform."
}

variable "address" {
  description = "Optional starting IPv4 address for the allocated range."
  type        = string
  default     = null

  validation {
    condition = (
      var.address == null ||
      can(cidrhost("${var.address}/32", 0))
    )

    error_message = "address must be a valid IPv4 address."
  }
}

variable "prefix_length" {
  description = "Prefix length of the allocated Private Service Access range."
  type        = number
  default     = 16

  validation {
    condition = (
      var.prefix_length >= 16 &&
      var.prefix_length <= 24
    )

    error_message = "prefix_length must be between 16 and 24."
  }
}


# -----------------------------------------------------------------------------
# Service Networking Connection
#
# For supported Google-managed services, the service producer is normally:
#
# servicenetworking.googleapis.com
# -----------------------------------------------------------------------------

variable "service" {
  description = "Service producer used by the Private Service Access connection."
  type        = string
  default     = "servicenetworking.googleapis.com"

  validation {
    condition     = trimspace(var.service) != ""
    error_message = "service must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Connection Lifecycle
#
# PREVENT:
#   Blocks Terraform from deleting the Service Networking connection.
#
# ABANDON:
#   Removes the connection from Terraform state without deleting the
#   connection or generated VPC peering.
#
# DELETE:
#   Requests normal deletion of the Service Networking connection.
#
# REMOVE_PEERING:
#   Removes the generated VPC peering as a teardown escape hatch. This should
#   only be used after dependent managed-service resources have been removed.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Connection Lifecycle
#
# PREVENT:
#   Prevents Terraform from deleting the Service Networking connection.
#
# ABANDON:
#   Removes the resource from Terraform management without deleting the
#   connection through the API.
#
# DELETE:
#   Allows Terraform to request deletion of the connection.
# -----------------------------------------------------------------------------

variable "deletion_policy" {
  description = "Deletion policy for the Service Networking connection."
  type        = string
  default     = "PREVENT"

  validation {
    condition = contains(
      [
        "PREVENT",
        "ABANDON",
        "DELETE"
      ],
      upper(var.deletion_policy)
    )

    error_message = "deletion_policy must be PREVENT, ABANDON, or DELETE."
  }
}


# -----------------------------------------------------------------------------
# Existing Connection Update Behavior
#
# When enabled, Terraform can attempt to update the reserved peering ranges if
# creation fails because a Service Networking connection already exists.
# -----------------------------------------------------------------------------

variable "update_on_creation_fail" {
  description = "Attempt to update reserved ranges when connection creation fails because a connection already exists."
  type        = bool
  default     = false
}


# -----------------------------------------------------------------------------
# Optional Custom Route Exchange
#
# When both values are false, the reusable module does not create a
# google_compute_network_peering_routes_config resource.
# -----------------------------------------------------------------------------

variable "import_custom_routes" {
  description = "Import custom routes from the service producer peering."
  type        = bool
  default     = false
}

variable "export_custom_routes" {
  description = "Export custom routes to the service producer peering."
  type        = bool
  default     = false
}
