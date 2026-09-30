# -----------------------------------------------------------------------------
# GCP Regional Managed Instance Group
#
# This reusable module creates:
#
# - One regional Managed Instance Group
# - Optional named ports
# - Optional autohealing
# - Rolling update configuration
# - Optional regional CPU-based autoscaler
#
# The module consumes an existing instance template.
#
# The module intentionally does not create:
#
# - Instance templates
# - Health checks
# - VPC networks
# - Subnets
# - Service accounts
# - Firewall rules
# - Load balancers
# - IAM bindings
# -----------------------------------------------------------------------------


# =============================================================================
# REGIONAL MANAGED INSTANCE GROUP
# =============================================================================

resource "google_compute_region_instance_group_manager" "this" {
  project = var.project_id
  region  = var.region

  name               = var.name
  description        = var.description
  base_instance_name = var.base_instance_name


  # ---------------------------------------------------------------------------
  # Instance Template Version
  # ---------------------------------------------------------------------------

  version {
    name              = var.version_name
    instance_template = var.instance_template_self_link
  }


  # ---------------------------------------------------------------------------
  # Regional Distribution
  # ---------------------------------------------------------------------------

  distribution_policy_zones = (
    length(var.distribution_policy_zones) > 0
    ? var.distribution_policy_zones
    : null
  )

  distribution_policy_target_shape = upper(
    var.distribution_policy_target_shape
  )


  # ---------------------------------------------------------------------------
  # Group Size
  #
  # target_size supplies the initial group size.
  #
  # lifecycle.ignore_changes prevents Terraform from attempting to reconcile
  # autoscaler-driven target-size changes.
  # ---------------------------------------------------------------------------

  target_size = var.target_size


  # ---------------------------------------------------------------------------
  # Instance Readiness
  # ---------------------------------------------------------------------------

  wait_for_instances = var.wait_for_instances

  wait_for_instances_status = upper(
    var.wait_for_instances_status
  )


  # ---------------------------------------------------------------------------
  # Named Ports
  # ---------------------------------------------------------------------------

  dynamic "named_port" {
    for_each = var.named_ports

    content {
      name = named_port.key
      port = named_port.value
    }
  }


  # ---------------------------------------------------------------------------
  # Autohealing
  #
  # The health check is managed outside this module.
  # ---------------------------------------------------------------------------

  dynamic "auto_healing_policies" {
    for_each = var.enable_autohealing ? [1] : []

    content {
      health_check = var.health_check_id

      initial_delay_sec = (
        var.initial_delay_sec
      )
    }
  }


  # ---------------------------------------------------------------------------
  # Rolling Update Policy
  # ---------------------------------------------------------------------------

  update_policy {
    type = upper(
      var.update_type
    )

    minimal_action = upper(
      var.minimal_action
    )

    most_disruptive_allowed_action = upper(
      var.most_disruptive_allowed_action
    )

    replacement_method = upper(
      var.replacement_method
    )

    max_surge_fixed = var.max_surge_fixed

    max_unavailable_fixed = (
      var.max_unavailable_fixed
    )
  }


  # ---------------------------------------------------------------------------
  # Lifecycle and Validation
  # ---------------------------------------------------------------------------

  lifecycle {
    # -------------------------------------------------------------------------
    # The autoscaler can modify target_size independently of Terraform.
    #
    # Ignoring target_size prevents Terraform from continually attempting to
    # restore the configured starting size after autoscaling events.
    # -------------------------------------------------------------------------

    ignore_changes = [
      target_size
    ]

    # -------------------------------------------------------------------------
    # Autohealing requires an existing health check.
    # -------------------------------------------------------------------------

    precondition {
      condition = (
        !var.enable_autohealing ||
        (
          var.health_check_id != null &&
          trimspace(var.health_check_id) != ""
        )
      )

      error_message = "health_check_id must be supplied when enable_autohealing is true."
    }
  }
}


# =============================================================================
# REGIONAL AUTOSCALER
# =============================================================================

resource "google_compute_region_autoscaler" "this" {
  count = var.enable_autoscaling ? 1 : 0

  project = var.project_id
  region  = var.region

  name = (
    var.autoscaler_name != null
    ? var.autoscaler_name
    : "${var.name}-autoscaler"
  )

  target = (
    google_compute_region_instance_group_manager.this.id
  )


  # ---------------------------------------------------------------------------
  # Autoscaling Policy
  #
  # This initial implementation uses CPU-based autoscaling only.
  # ---------------------------------------------------------------------------

  autoscaling_policy {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    cooldown_period = (
      var.cooldown_period_sec
    )

    cpu_utilization {
      target = (
        var.cpu_utilization_target
      )
    }
  }


  # ---------------------------------------------------------------------------
  # Autoscaler Validation
  # ---------------------------------------------------------------------------

  lifecycle {
    precondition {
      condition = (
        var.max_replicas >= var.min_replicas
      )

      error_message = "max_replicas must be greater than or equal to min_replicas."
    }
  }
}
