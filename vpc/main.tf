resource "google_compute_network" "this" {
  count = var.create_vpc ? 1 : 0

  project                         = var.project_id
  name                            = var.network_name
  description                     = var.description
  auto_create_subnetworks         = false
  routing_mode                    = upper(var.routing_mode)
  delete_default_routes_on_create = var.delete_default_routes_on_create
  mtu                             = var.mtu
}

data "google_compute_network" "existing" {
  count = var.create_vpc ? 0 : 1

  project = var.project_id
  name    = var.existing_network_name
}

resource "google_compute_subnetwork" "this" {
  for_each = var.create_subnets ? var.subnets : {}

  project = var.project_id

  name          = each.value.name
  region        = each.value.region
  network       = local.network_self_link
  ip_cidr_range = each.value.ip_cidr_range

  description = try(
    each.value.description,
    null
  )

  private_ip_google_access = try(
    each.value.private_ip_google_access,
    true
  )

  dynamic "secondary_ip_range" {
    for_each = try(
      each.value.secondary_ip_ranges,
      {}
    )

    content {
      range_name = secondary_ip_range.value.range_name

      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }

  dynamic "log_config" {
    for_each = try(each.value.log_config, null) == null ? [] : [each.value.log_config]

    content {
      aggregation_interval = try(
        log_config.value.aggregation_interval,
        "INTERVAL_5_SEC"
      )

      flow_sampling = try(
        log_config.value.flow_sampling,
        0.5
      )

      metadata = try(
        log_config.value.metadata,
        "INCLUDE_ALL_METADATA"
      )
    }
  }
}
