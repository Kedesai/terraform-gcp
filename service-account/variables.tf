variable "project_id" {
  description = "GCP project ID containing the service account."
  type        = string
}

variable "create_service_account" {
  description = "Whether to create a new service account."
  type        = bool
  default     = true
}

variable "account_id" {
  description = "Service account ID when creating a new service account."
  type        = string
  default     = null
}

variable "display_name" {
  description = "Display name for the service account."
  type        = string
  default     = null
}

variable "description" {
  description = "Description for the service account."
  type        = string
  default     = null
}

variable "existing_service_account_email" {
  description = "Email address of an existing service account when create_service_account is false."
  type        = string
  default     = null
}

variable "project_roles" {
  description = "Project-level IAM roles to assign to the service account."
  type        = set(string)
  default     = []
}
