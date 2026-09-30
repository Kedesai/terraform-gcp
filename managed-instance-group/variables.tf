# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project containing the regional Managed Instance Group."
  type        = string

  validation {
    condition     = trimspace(var.project_id) != ""
    error_message = "project_id must not be empty."
  }
}

variable "region" {
  description = "GCP region containing the regional Managed Instance Group."
  type        = string

  validation {
    condition     = trimspace(var.region) != ""
    error_message = "region must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Managed Instance Group Identity
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the regional Managed Instance Group."
  type        = string

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "description" {
  description = "Optional description of the regional Managed Instance Group."
  type        = string
  default     = null
}

variable "base_instance_name" {
  description = "Base name assigned to VM instances created by the group."
  type        = string

  validation {
    condition     = trimspace(var.base_instance_name) != ""
    error_message = "base_instance_name must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Existing Instance Template
#
# Instance-template creation remains outside this reusable module.
# -----------------------------------------------------------------------------

variable "instance_template_self_link" {
  description = "Self-link of the existing instance template used by the Managed Instance Group."
  type        = string

  validation {
    condition     = trimspace(var.instance_template_self_link) != ""
    error_message = "instance_template_self_link must not be empty."
  }
}

variable "version_name" {
  description = "Name assigned to the primary Managed Instance Group version."
  type        = string
  default     = "primary"

  validation {
    condition     = trimspace(var.version_name) != ""
    error_message = "version_name must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Regional Distribution
# -----------------------------------------------------------------------------

variable "distribution_policy_zones" {
  description = "Optional zones used by the regional Managed Instance Group."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for zone in var.distribution_policy_zones :
      trimspace(zone) != ""
    ])

    error_message = "distribution_policy_zones cannot contain empty zone names."
  }
}

variable "distribution_policy_target_shape" {
  description = "Target distribution shape for instances across zones."
  type        = string
  default     = "EVEN"

  validation {
    condition = contains(
      [
        "EVEN",
        "BALANCED",
        "ANY",
        "ANY_SINGLE_ZONE"
      ],
      upper(var.distribution_policy_target_shape)
    )

    error_message = "distribution_policy_target_shape must be EVEN, BALANCED, ANY, or ANY_SINGLE_ZONE."
  }
}


# -----------------------------------------------------------------------------
# Group Size
#
# target_size provides the initial/configured MIG size.
#
# Terraform ignores subsequent target_size changes on the MIG resource because
# an enabled autoscaler can modify this value independently.
# -----------------------------------------------------------------------------

variable "target_size" {
  description = "Configured target number of instances in the Managed Instance Group."
  type        = number
  default     = 2

  validation {
    condition     = var.target_size >= 0
    error_message = "target_size must be zero or greater."
  }
}


# -----------------------------------------------------------------------------
# Instance Readiness
# -----------------------------------------------------------------------------

variable "wait_for_instances" {
  description = "Wait for Managed Instance Group instances before completing the operation."
  type        = bool
  default     = true
}

variable "wait_for_instances_status" {
  description = "Instance status required when wait_for_instances is enabled."
  type        = string
  default     = "STABLE"

  validation {
    condition = contains(
      [
        "STABLE",
        "UPDATED"
      ],
      upper(var.wait_for_instances_status)
    )

    error_message = "wait_for_instances_status must be STABLE or UPDATED."
  }
}


# -----------------------------------------------------------------------------
# Named Ports
# -----------------------------------------------------------------------------

variable "named_ports" {
  description = "Named ports exposed by the Managed Instance Group."
  type        = map(number)
  default     = {}

  validation {
    condition = alltrue([
      for port in values(var.named_ports) :
      port >= 1 && port <= 65535
    ])

    error_message = "Every named port must be between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for port_name in keys(var.named_ports) :
      trimspace(port_name) != ""
    ])

    error_message = "Named port names must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Autohealing
#
# Health-check creation remains outside this module.
# -----------------------------------------------------------------------------

variable "enable_autohealing" {
  description = "Enable autohealing for unhealthy Managed Instance Group instances."
  type        = bool
  default     = false
}

variable "health_check_id" {
  description = "Compute Engine health-check ID or self-link used for autohealing."
  type        = string
  default     = null
}

variable "initial_delay_sec" {
  description = "Initial delay before autohealing health checks evaluate a new instance."
  type        = number
  default     = 300

  validation {
    condition     = var.initial_delay_sec >= 0
    error_message = "initial_delay_sec must be zero or greater."
  }
}


# -----------------------------------------------------------------------------
# Rolling Update Policy
# -----------------------------------------------------------------------------

variable "update_type" {
  description = "Managed Instance Group update type."
  type        = string
  default     = "PROACTIVE"

  validation {
    condition = contains(
      [
        "PROACTIVE",
        "OPPORTUNISTIC"
      ],
      upper(var.update_type)
    )

    error_message = "update_type must be PROACTIVE or OPPORTUNISTIC."
  }
}

variable "minimal_action" {
  description = "Minimum action performed during an instance update."
  type        = string
  default     = "REPLACE"

  validation {
    condition = contains(
      [
        "NONE",
        "REFRESH",
        "RESTART",
        "REPLACE"
      ],
      upper(var.minimal_action)
    )

    error_message = "minimal_action must be NONE, REFRESH, RESTART, or REPLACE."
  }
}

variable "most_disruptive_allowed_action" {
  description = "Most disruptive action permitted during an instance update."
  type        = string
  default     = "REPLACE"

  validation {
    condition = contains(
      [
        "NONE",
        "REFRESH",
        "RESTART",
        "REPLACE"
      ],
      upper(var.most_disruptive_allowed_action)
    )

    error_message = "most_disruptive_allowed_action must be NONE, REFRESH, RESTART, or REPLACE."
  }
}

variable "replacement_method" {
  description = "Method used when replacing Managed Instance Group instances."
  type        = string
  default     = "SUBSTITUTE"

  validation {
    condition = contains(
      [
        "RECREATE",
        "SUBSTITUTE"
      ],
      upper(var.replacement_method)
    )

    error_message = "replacement_method must be RECREATE or SUBSTITUTE."
  }
}

variable "max_surge_fixed" {
  description = "Maximum fixed number of additional instances created during an update."
  type        = number
  default     = 1

  validation {
    condition     = var.max_surge_fixed >= 0
    error_message = "max_surge_fixed must be zero or greater."
  }
}

variable "max_unavailable_fixed" {
  description = "Maximum fixed number of unavailable instances during an update."
  type        = number
  default     = 0

  validation {
    condition     = var.max_unavailable_fixed >= 0
    error_message = "max_unavailable_fixed must be zero or greater."
  }
}


# -----------------------------------------------------------------------------
# Autoscaling
#
# This version supports CPU-based regional autoscaling.
# -----------------------------------------------------------------------------

variable "enable_autoscaling" {
  description = "Create a regional autoscaler for the Managed Instance Group."
  type        = bool
  default     = true
}

variable "autoscaler_name" {
  description = "Optional name of the regional autoscaler."
  type        = string
  default     = null

  validation {
    condition = (
      var.autoscaler_name == null ||
      trimspace(var.autoscaler_name) != ""
    )

    error_message = "autoscaler_name must be null or a non-empty string."
  }
}

variable "min_replicas" {
  description = "Minimum number of instances maintained by the autoscaler."
  type        = number
  default     = 2

  validation {
    condition     = var.min_replicas >= 0
    error_message = "min_replicas must be zero or greater."
  }
}

variable "max_replicas" {
  description = "Maximum number of instances maintained by the autoscaler."
  type        = number
  default     = 5

  validation {
    condition     = var.max_replicas >= 0
    error_message = "max_replicas must be zero or greater."
  }
}

variable "cooldown_period_sec" {
  description = "Autoscaler cooldown period in seconds."
  type        = number
  default     = 60

  validation {
    condition     = var.cooldown_period_sec >= 0
    error_message = "cooldown_period_sec must be zero or greater."
  }
}

variable "cpu_utilization_target" {
  description = "Target average CPU utilization used by the autoscaler."
  type        = number
  default     = 0.60

  validation {
    condition = (
      var.cpu_utilization_target > 0 &&
      var.cpu_utilization_target <= 1
    )

    error_message = "cpu_utilization_target must be greater than zero and no greater than one."
  }
}
