# -----------------------------------------------------------------------------
# Private Service Access
#
# Private Service Access provides private communication between an existing
# consumer VPC and a supported Google-managed service-producer network.
#
# This module creates:
#
# - One globally allocated VPC peering address range
# - One Service Networking private connection
# - Optional custom-route exchange configuration
#
# This module does not create:
#
# - VPC networks
# - Subnets
# - Cloud SQL
# - Google Cloud projects
# - API enablement
# - IAM bindings
# -----------------------------------------------------------------------------


# =============================================================================
# ALLOCATED PRIVATE RANGE
# =============================================================================

# -----------------------------------------------------------------------------
# Global Address Allocation
#
# The address is reserved for VPC peering and made available to supported
# service producers through the Service Networking connection.
# -----------------------------------------------------------------------------

resource "google_compute_global_address" "this" {
  project = var.project_id

  name        = var.allocated_range_name
  description = var.allocated_range_description

  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"

  network = var.network_id

  address       = var.address
  prefix_length = var.prefix_length
}


# =============================================================================
# SERVICE NETWORKING CONNECTION
# =============================================================================

# -----------------------------------------------------------------------------
# Private Service Connection
#
# Connects the existing consumer VPC to Google's service-producer network.
#
# reserved_peering_ranges accepts the NAME of the allocated global address,
# not its CIDR address or resource ID.
# -----------------------------------------------------------------------------

resource "google_service_networking_connection" "this" {
  network = var.network_id
  service = var.service

  reserved_peering_ranges = [
    google_compute_global_address.this.name
  ]

  deletion_policy = upper(
    var.deletion_policy
  )

  update_on_creation_fail = (
    var.update_on_creation_fail
  )
}


# =============================================================================
# OPTIONAL CUSTOM ROUTE EXCHANGE
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Peering Routes
#
# This resource is created only when import or export of custom routes is
# enabled.
#
# The peering name is returned by the Service Networking connection.
# -----------------------------------------------------------------------------

resource "google_compute_network_peering_routes_config" "this" {
  count = (
    var.import_custom_routes ||
    var.export_custom_routes
  ) ? 1 : 0

  project = var.project_id

  network = var.network_name
  peering = google_service_networking_connection.this.peering

  import_custom_routes = var.import_custom_routes
  export_custom_routes = var.export_custom_routes
}
