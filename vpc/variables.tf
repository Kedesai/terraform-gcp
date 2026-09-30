variable "project_id" {
  description = "GCP project ID where the VPC resources will be managed."
  type        = string
}

variable "create_vpc" {
  description = "Whether to create a new VPC network."
  type        = bool
  default     = true
}

variable "network_name" {
  description = "Name of the VPC network to create."
  type        = string
  default     = null
}

variable "existing_network_name" {
  description = "Name of an existing VPC network when create_vpc is false."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the VPC network."
  type        = string
  default     = null
}

variable "routing_mode" {
  description = "Network-wide routing mode. Valid values are REGIONAL or GLOBAL."
  type        = string
  default     = "GLOBAL"

  validation {
    condition = contains(
      ["REGIONAL", "GLOBAL"],
      upper(var.routing_mode)
    )
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "delete_default_routes_on_create" {
  description = "Whether default routes should be deleted when creating the VPC."
  type        = bool
  default     = false
}

variable "mtu" {
  description = "Maximum Transmission Unit for the VPC."
  type        = number
  default     = 1460
}

variable "create_subnets" {
  description = "Whether this module should create subnets."
  type        = bool
  default     = true
}

variable "subnets" {
  description = "Map of subnets to create in the VPC."

  type = map(object({
    name                     = string
    region                   = string
    ip_cidr_range            = string
    private_ip_google_access = optional(bool, true)
    description              = optional(string)

    secondary_ip_ranges = optional(map(object({
      range_name    = string
      ip_cidr_range = string
    })), {})

    log_config = optional(object({
      aggregation_interval = optional(string, "INTERVAL_5_SEC")
      flow_sampling        = optional(number, 0.5)
      metadata             = optional(string, "INCLUDE_ALL_METADATA")
    }))
  }))

  default = {}
}

variable "labels" {
  description = "Labels to apply where supported."
  type        = map(string)
  default     = {}
}
