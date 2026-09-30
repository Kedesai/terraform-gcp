# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project containing the load balancer resources."
  type        = string

  validation {
    condition     = trimspace(var.project_id) != ""
    error_message = "project_id must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Load Balancer Identity
# -----------------------------------------------------------------------------

variable "name" {
  description = "Base name used for the load balancer resources."
  type        = string

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Managed Instance Group Backend
# -----------------------------------------------------------------------------

variable "backend_instance_group" {
  description = "Instance group self-link or ID used by the backend service."
  type        = string

  validation {
    condition     = trimspace(var.backend_instance_group) != ""
    error_message = "backend_instance_group must not be empty."
  }
}

variable "backend_protocol" {
  description = "Protocol used between the load balancer and backend."
  type        = string
  default     = "HTTP"

  validation {
    condition = contains(
      [
        "HTTP",
        "HTTPS",
        "HTTP2"
      ],
      upper(var.backend_protocol)
    )

    error_message = "backend_protocol must be HTTP, HTTPS, or HTTP2."
  }
}

variable "port_name" {
  description = "Named port exposed by the Managed Instance Group."
  type        = string
  default     = "http"

  validation {
    condition     = trimspace(var.port_name) != ""
    error_message = "port_name must not be empty."
  }
}

variable "timeout_sec" {
  description = "Backend service timeout in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.timeout_sec > 0
    error_message = "timeout_sec must be greater than zero."
  }
}

variable "enable_cdn" {
  description = "Enable Cloud CDN on the backend service."
  type        = bool
  default     = false
}


# -----------------------------------------------------------------------------
# Backend Balancing
#
# The initial module supports UTILIZATION balancing only.
#
# RATE and CONNECTION modes require additional mode-specific inputs that are
# deliberately outside the current v1 interface.
# -----------------------------------------------------------------------------

variable "balancing_mode" {
  description = "Backend balancing mode. The initial module supports UTILIZATION."
  type        = string
  default     = "UTILIZATION"

  validation {
    condition = (
      upper(var.balancing_mode) == "UTILIZATION"
    )

    error_message = "balancing_mode must be UTILIZATION."
  }
}

variable "capacity_scaler" {
  description = "Fraction of backend capacity available to the load balancer."
  type        = number
  default     = 1.0

  validation {
    condition = (
      var.capacity_scaler >= 0 &&
      var.capacity_scaler <= 1
    )

    error_message = "capacity_scaler must be between 0 and 1."
  }
}

variable "max_utilization" {
  description = "Maximum backend utilization used by UTILIZATION balancing."
  type        = number
  default     = 0.8

  validation {
    condition = (
      var.max_utilization > 0 &&
      var.max_utilization <= 1
    )

    error_message = "max_utilization must be greater than zero and no greater than one."
  }
}


# -----------------------------------------------------------------------------
# HTTP Health Check
# -----------------------------------------------------------------------------

variable "health_check_port" {
  description = "TCP port used by the HTTP health check."
  type        = number
  default     = 8080

  validation {
    condition = (
      var.health_check_port >= 1 &&
      var.health_check_port <= 65535
    )

    error_message = "health_check_port must be between 1 and 65535."
  }
}

variable "health_check_request_path" {
  description = "HTTP request path used by the load balancer health check."
  type        = string
  default     = "/"

  validation {
    condition = (
      startswith(var.health_check_request_path, "/")
    )

    error_message = "health_check_request_path must start with '/'."
  }
}

variable "health_check_interval_sec" {
  description = "Health-check interval in seconds."
  type        = number
  default     = 10

  validation {
    condition     = var.health_check_interval_sec > 0
    error_message = "health_check_interval_sec must be greater than zero."
  }
}

variable "health_check_timeout_sec" {
  description = "Health-check timeout in seconds."
  type        = number
  default     = 5

  validation {
    condition     = var.health_check_timeout_sec > 0
    error_message = "health_check_timeout_sec must be greater than zero."
  }
}

variable "healthy_threshold" {
  description = "Number of successful checks required for healthy status."
  type        = number
  default     = 2

  validation {
    condition     = var.healthy_threshold > 0
    error_message = "healthy_threshold must be greater than zero."
  }
}

variable "unhealthy_threshold" {
  description = "Number of failed checks required for unhealthy status."
  type        = number
  default     = 3

  validation {
    condition     = var.unhealthy_threshold > 0
    error_message = "unhealthy_threshold must be greater than zero."
  }
}


# -----------------------------------------------------------------------------
# Backend-Service Request Logging
# -----------------------------------------------------------------------------

variable "enable_logging" {
  description = "Enable backend-service request logging."
  type        = bool
  default     = true
}

variable "log_sample_rate" {
  description = "Fraction of requests written to load-balancer logs."
  type        = number
  default     = 1.0

  validation {
    condition = (
      var.log_sample_rate >= 0 &&
      var.log_sample_rate <= 1
    )

    error_message = "log_sample_rate must be between 0 and 1."
  }
}
