# -----------------------------------------------------------------------------
# Terraform and Provider Requirements
#
# This reusable module declares its Google provider requirement but does not
# configure the provider or authentication.
#
# Provider configuration belongs to the caller.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0, < 8.0"
    }
  }
}
