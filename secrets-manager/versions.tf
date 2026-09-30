# -----------------------------------------------------------------------------
# Terraform and Provider Requirements
#
# This reusable module declares the Google provider requirement but does not
# configure the provider or authentication.
#
# Provider configuration belongs in the calling module and is inherited by
# this reusable module.
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
