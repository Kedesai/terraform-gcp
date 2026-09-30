# -----------------------------------------------------------------------------
# Terraform and Provider Requirements
#
# This reusable module declares its Terraform and Google provider requirements.
#
# Provider configuration and authentication belong to the caller and are
# inherited by this module.
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
