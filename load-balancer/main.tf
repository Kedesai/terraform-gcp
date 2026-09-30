# -----------------------------------------------------------------------------
# Global External HTTP Application Load Balancer
#
# This reusable module creates:
#
# - Global external IPv4 address
# - HTTP health check
# - Global backend service
# - URL map
# - Target HTTP proxy
# - Global HTTP forwarding rule
#
# This module consumes an existing Managed Instance Group.
#
# The module intentionally does not create:
#
# - VPC networks
# - Subnets
# - Instance templates
# - Managed Instance Groups
# - Firewall rules
# - DNS records
# - TLS certificates
# - IAM bindings
# -----------------------------------------------------------------------------


# =============================================================================
# GLOBAL EXTERNAL IP ADDRESS
# =============================================================================

resource "google_compute_global_address" "this" {
  project = var.project_id

  name = "${var.name}-ip"
}


# =============================================================================
# HTTP HEALTH CHECK
# =============================================================================

resource "google_compute_health_check" "this" {
  project = var.project_id

  name = "${var.name}-health-check"

  check_interval_sec = (
    var.health_check_interval_sec
  )

  timeout_sec = (
    var.health_check_timeout_sec
  )

  healthy_threshold = (
    var.healthy_threshold
  )

  unhealthy_threshold = (
    var.unhealthy_threshold
  )

  http_health_check {
    port = var.health_check_port

    request_path = (
      var.health_check_request_path
    )
  }

  lifecycle {
    precondition {
      condition = (
        var.health_check_timeout_sec <=
        var.health_check_interval_sec
      )

      error_message = "health_check_timeout_sec must be less than or equal to health_check_interval_sec."
    }
  }
}


# =============================================================================
# GLOBAL BACKEND SERVICE
# =============================================================================

resource "google_compute_backend_service" "this" {
  project = var.project_id

  name = "${var.name}-backend"

  protocol = upper(
    var.backend_protocol
  )

  port_name = var.port_name

  timeout_sec = (
    var.timeout_sec
  )

  load_balancing_scheme = "EXTERNAL_MANAGED"

  enable_cdn = (
    var.enable_cdn
  )

  health_checks = [
    google_compute_health_check.this.id
  ]

  backend {
    group = var.backend_instance_group

    balancing_mode = "UTILIZATION"

    capacity_scaler = (
      var.capacity_scaler
    )

    max_utilization = (
      var.max_utilization
    )
  }

  log_config {
    enable = var.enable_logging

    sample_rate = (
      var.log_sample_rate
    )
  }
}


# =============================================================================
# URL MAP
# =============================================================================

resource "google_compute_url_map" "this" {
  project = var.project_id

  name = "${var.name}-url-map"

  default_service = (
    google_compute_backend_service.this.id
  )

  lifecycle {
    create_before_destroy = true
  }
}


# =============================================================================
# TARGET HTTP PROXY
# =============================================================================

resource "google_compute_target_http_proxy" "this" {
  project = var.project_id

  name = "${var.name}-http-proxy"

  url_map = (
    google_compute_url_map.this.id
  )

  lifecycle {
    create_before_destroy = true
  }
}


# =============================================================================
# GLOBAL HTTP FORWARDING RULE
# =============================================================================

resource "google_compute_global_forwarding_rule" "http" {
  project = var.project_id

  name = "${var.name}-http-forwarding-rule"

  ip_address = (
    google_compute_global_address.this.address
  )

  ip_protocol = "TCP"
  port_range  = "80"

  load_balancing_scheme = "EXTERNAL_MANAGED"

  target = (
    google_compute_target_http_proxy.this.id
  )
}
