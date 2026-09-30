# -----------------------------------------------------------------------------
# Google Compute Engine VM Instances
#
# Creates one or more Compute Engine VM instances from var.instances.
#
# This reusable module intentionally does not create:
#
# - VPC networks
# - Subnets
# - Service accounts
# - IAM roles
# - KMS keys
# - Firewall rules
#
# Those capabilities belong to separate reusable modules. Their outputs are
# supplied to this module through the caller.
# -----------------------------------------------------------------------------

resource "google_compute_instance" "this" {
  for_each = var.instances

  project = var.project_id


  # ---------------------------------------------------------------------------
  # Basic VM Configuration
  # ---------------------------------------------------------------------------

  name         = each.value.name
  zone         = each.value.zone
  machine_type = each.value.machine_type

  description      = each.value.description
  hostname         = each.value.hostname
  min_cpu_platform = each.value.min_cpu_platform

  labels = each.value.labels
  tags   = each.value.tags


  # ---------------------------------------------------------------------------
  # VM Protection and Update Behavior
  #
  # deletion_protection must be disabled before Terraform can destroy the VM.
  #
  # allow_stopping_for_update permits Terraform to stop the instance when a
  # requested update cannot be completed while the VM is running.
  # ---------------------------------------------------------------------------

  deletion_protection       = each.value.deletion_protection
  allow_stopping_for_update = each.value.allow_stopping_for_update
  can_ip_forward            = each.value.can_ip_forward


  # ---------------------------------------------------------------------------
  # Boot Disk
  #
  # The boot disk is initialized from the caller-selected image.
  #
  # CMEK is optional. When kms_key_id is null, the boot disk uses the default
  # encryption configuration.
  # ---------------------------------------------------------------------------

  boot_disk {
    auto_delete = each.value.boot_disk.auto_delete
    device_name = each.value.boot_disk.device_name

    initialize_params {
      image = each.value.boot_disk.image
      size  = each.value.boot_disk.size_gb
      type  = each.value.boot_disk.type

      labels = each.value.boot_disk.labels
    }

    kms_key_self_link = each.value.boot_disk.kms_key_id
  }


  # ---------------------------------------------------------------------------
  # Network Interface
  #
  # The subnetwork is supplied by the caller and should normally consume the
  # subnet-self-link output from the reusable VPC module.
  #
  # An external IP is not assigned unless assign_external_ip is explicitly
  # enabled.
  # ---------------------------------------------------------------------------

  network_interface {
    subnetwork = each.value.network_interface.subnetwork

    subnetwork_project = each.value.network_interface.subnetwork_project
    network_ip         = each.value.network_interface.network_ip

    stack_type = each.value.network_interface.stack_type
    nic_type   = each.value.network_interface.nic_type


    # -------------------------------------------------------------------------
    # Optional External IPv4 Address
    #
    # Omitting access_config leaves the VM without an external IPv4 address.
    # -------------------------------------------------------------------------

    dynamic "access_config" {
      for_each = each.value.network_interface.assign_external_ip ? [1] : []

      content {
        nat_ip = each.value.network_interface.nat_ip

        network_tier = upper(
          each.value.network_interface.network_tier
        )
      }
    }
  }


  # ---------------------------------------------------------------------------
  # Service Account
  #
  # The service-account block is generated only when the caller supplies a
  # service account.
  #
  # This module does not create the service account or manage its IAM roles.
  # ---------------------------------------------------------------------------

  dynamic "service_account" {
    for_each = each.value.service_account == null ? [] : [
      each.value.service_account
    ]

    content {
      email  = service_account.value.email
      scopes = service_account.value.scopes
    }
  }


  # ---------------------------------------------------------------------------
  # Instance Metadata
  #
  # Metadata is visible to the guest operating system.
  #
  # Passwords, certificates, tokens and other sensitive values must not be
  # stored in VM metadata.
  # ---------------------------------------------------------------------------

  metadata = each.value.metadata


  # ---------------------------------------------------------------------------
  # Startup Script
  #
  # The startup script is optional and is passed directly to Compute Engine.
  #
  # It can bootstrap the VM but must not contain embedded secrets.
  # ---------------------------------------------------------------------------

  metadata_startup_script = each.value.startup_script


  # ---------------------------------------------------------------------------
  # Scheduling
  #
  # Controls restart behavior, host-maintenance behavior and provisioning
  # model.
  # ---------------------------------------------------------------------------

  scheduling {
    automatic_restart = (
      each.value.scheduling.automatic_restart
    )

    on_host_maintenance = upper(
      each.value.scheduling.on_host_maintenance
    )

    preemptible = (
      each.value.scheduling.preemptible
    )

    provisioning_model = upper(
      each.value.scheduling.provisioning_model
    )
  }


  # ---------------------------------------------------------------------------
  # Shielded VM
  #
  # Virtual TPM and integrity monitoring default to enabled.
  #
  # Secure Boot is caller-controlled because compatibility can depend on the
  # selected operating-system image and guest software.
  # ---------------------------------------------------------------------------

  shielded_instance_config {
    enable_secure_boot = (
      each.value.shielded_instance_config.enable_secure_boot
    )

    enable_vtpm = (
      each.value.shielded_instance_config.enable_vtpm
    )

    enable_integrity_monitoring = (
      each.value.shielded_instance_config.enable_integrity_monitoring
    )
  }


  # ---------------------------------------------------------------------------
  # Confidential Computing
  #
  # This block is created only when Confidential Computing is enabled.
  #
  # The caller must provide a compatible machine type, CPU platform, zone and
  # scheduling configuration.
  # ---------------------------------------------------------------------------

  dynamic "confidential_instance_config" {
    for_each = each.value.confidential_compute.enabled ? [1] : []

    content {
      enable_confidential_compute = true

      confidential_instance_type = (
        each.value.confidential_compute.type
      )
    }
  }
}
