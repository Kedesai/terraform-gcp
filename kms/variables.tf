variable "project_id" {
  description = "GCP project ID where KMS resources will be managed."
  type        = string
}

variable "location" {
  description = "Location of the KMS Key Ring."
  type        = string
  default     = "global"
}

variable "create_key_ring" {
  description = "Whether to create a new KMS Key Ring."
  type        = bool
  default     = true
}

variable "key_ring_name" {
  description = "Name of the KMS Key Ring to create."
  type        = string
  default     = null
}

variable "existing_key_ring_name" {
  description = "Name of an existing KMS Key Ring when create_key_ring is false."
  type        = string
  default     = null
}

variable "keys" {
  description = "Map of KMS Crypto Keys to create."

  type = map(object({
    name            = string
    purpose         = optional(string, "ENCRYPT_DECRYPT")
    rotation_period = optional(string, "7776000s")

    destroy_scheduled_duration = optional(string, "2592000s")

    prevent_destroy = optional(bool, true)

    labels = optional(map(string), {})
  }))

  default = {}
}

variable "key_iam_members" {
  description = "IAM members and roles to assign to individual Crypto Keys."

  type = map(object({
    key  = string
    role = string

    members = set(string)
  }))

  default = {}
}
