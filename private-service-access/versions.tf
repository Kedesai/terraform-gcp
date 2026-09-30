# -----------------------------------------------------------------------------
# Terraform and Provider Requirements
#
# This reusable module declares the Google provider requirement.
#
# Provider configuration and authentication belong to the caller.
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
