# -----------------------------------------------------------------------------
# Terraform and Provider Requirements
#
# This reusable module declares the Google provider requirement.
#
# Provider configuration and authentication are intentionally not configured
# here. They are supplied by the calling Terraform configuration.
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
