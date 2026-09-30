# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where Compute Engine VM instances are created."
  type        = string
}


# -----------------------------------------------------------------------------
# Compute Engine VM Definitions
#
# The reusable module accepts a map so callers can create one or more VM
# instances.
#
# The map key is a logical Terraform identifier. The actual VM instance name
# is supplied through the name property.
# -----------------------------------------------------------------------------

variable "instances" {
  description = "Map of Compute Engine VM instances to create."

  type = map(object({

    # -------------------------------------------------------------------------
    # Basic VM Configuration
    # -------------------------------------------------------------------------

    name         = string
    zone         = string
    machine_type = string

    description      = optional(string)
    hostname         = optional(string)
    min_cpu_platform = optional(string)

    labels = optional(map(string), {})
    tags   = optional(list(string), [])


    # -------------------------------------------------------------------------
    # VM Protection and Update Behavior
    #
    # deletion_protection prevents accidental removal of the VM.
    #
    # allow_stopping_for_update permits Terraform to stop the VM when an update
    # cannot be performed while the instance is running.
    #
    # can_ip_forward should be enabled only for workloads that must forward
    # traffic, such as network appliances.
    # -------------------------------------------------------------------------

    deletion_protection       = optional(bool, true)
    allow_stopping_for_update = optional(bool, true)
    can_ip_forward            = optional(bool, false)


    # -------------------------------------------------------------------------
    # Boot Disk Configuration
    #
    # image can be an image name, image family, or fully qualified image
    # reference accepted by Compute Engine.
    #
    # kms_key_id is an optional fully qualified Cloud KMS Crypto Key ID.
    # -------------------------------------------------------------------------

    boot_disk = object({
      image = string

      size_gb = optional(number, 20)
      type    = optional(string, "pd-balanced")

      auto_delete = optional(bool, true)
      device_name = optional(string)

      labels = optional(map(string), {})

      kms_key_id = optional(string)
    })


    # -------------------------------------------------------------------------
    # Network Interface
    #
    # subnetwork should normally consume a subnet self-link from the reusable
    # VPC module.
    #
    # External IP assignment is disabled by default.
    # -------------------------------------------------------------------------

    network_interface = object({
      subnetwork = string

      subnetwork_project = optional(string)
      network_ip         = optional(string)

      stack_type = optional(string, "IPV4_ONLY")
      nic_type   = optional(string)

      assign_external_ip = optional(bool, false)
      nat_ip             = optional(string)
      network_tier       = optional(string, "PREMIUM")
    })


    # -------------------------------------------------------------------------
    # Service Account
    #
    # service_account.email should normally consume the email output from the
    # reusable service-account module.
    #
    # The cloud-platform scope is used as the default. Actual authorization
    # remains controlled through IAM roles assigned to the service account.
    # -------------------------------------------------------------------------

    service_account = optional(object({
      email  = string
      scopes = optional(list(string), ["cloud-platform"])
    }))


    # -------------------------------------------------------------------------
    # Metadata and Startup Script
    #
    # Sensitive values must not be placed in metadata or startup scripts.
    # Secret Manager or another approved mechanism should deliver secrets.
    # -------------------------------------------------------------------------

    metadata       = optional(map(string), {})
    startup_script = optional(string)


    # -------------------------------------------------------------------------
    # Scheduling
    #
    # This reusable module supports STANDARD and SPOT provisioning models.
    #
    # Spot instances require compatible restart and host-maintenance behavior.
    # -------------------------------------------------------------------------

    scheduling = optional(object({
      automatic_restart   = optional(bool, true)
      on_host_maintenance = optional(string, "MIGRATE")
      preemptible         = optional(bool, false)
      provisioning_model  = optional(string, "STANDARD")
    }), {})


    # -------------------------------------------------------------------------
    # Shielded VM Configuration
    #
    # Virtual TPM and integrity monitoring are enabled by default.
    #
    # Secure Boot remains disabled by default because compatibility can depend
    # on the selected image and guest software.
    # -------------------------------------------------------------------------

    shielded_instance_config = optional(object({
      enable_secure_boot          = optional(bool, false)
      enable_vtpm                 = optional(bool, true)
      enable_integrity_monitoring = optional(bool, true)
    }), {})


    # -------------------------------------------------------------------------
    # Confidential Computing
    #
    # Confidential Computing is optional and disabled by default.
    #
    # The caller is responsible for selecting a compatible machine type, zone,
    # CPU platform and scheduling configuration.
    # -------------------------------------------------------------------------

    confidential_compute = optional(object({
      enabled = optional(bool, false)
      type    = optional(string)
    }), {})
  }))

  default = {}


  # ---------------------------------------------------------------------------
  # Boot Disk Size Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      instance.boot_disk.size_gb > 0
    ])

    error_message = "Every boot_disk.size_gb value must be greater than zero."
  }


  # ---------------------------------------------------------------------------
  # Provisioning Model Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      contains(
        ["STANDARD", "SPOT"],
        upper(instance.scheduling.provisioning_model)
      )
    ])

    error_message = "scheduling.provisioning_model must be STANDARD or SPOT."
  }


  # ---------------------------------------------------------------------------
  # Host Maintenance Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      contains(
        ["MIGRATE", "TERMINATE"],
        upper(instance.scheduling.on_host_maintenance)
      )
    ])

    error_message = "scheduling.on_host_maintenance must be MIGRATE or TERMINATE."
  }


  # ---------------------------------------------------------------------------
  # Network Tier Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      contains(
        ["PREMIUM", "STANDARD"],
        upper(instance.network_interface.network_tier)
      )
    ])

    error_message = "network_interface.network_tier must be PREMIUM or STANDARD."
  }


  # ---------------------------------------------------------------------------
  # Spot Scheduling Validation
  #
  # Spot instances must not use automatic restart and must terminate during
  # host maintenance.
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for instance in values(var.instances) :
      upper(instance.scheduling.provisioning_model) != "SPOT" ||
      (
        instance.scheduling.automatic_restart == false &&
        upper(instance.scheduling.on_host_maintenance) == "TERMINATE"
      )
    ])

    error_message = "SPOT instances require automatic_restart = false and on_host_maintenance = TERMINATE."
  }
}
