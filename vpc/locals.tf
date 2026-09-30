locals {
  network_name = var.create_vpc ? (
    google_compute_network.this[0].name
  ) : var.existing_network_name

  network_id = var.create_vpc ? (
    google_compute_network.this[0].id
  ) : data.google_compute_network.existing[0].id

  network_self_link = var.create_vpc ? (
    google_compute_network.this[0].self_link
  ) : data.google_compute_network.existing[0].self_link
}
