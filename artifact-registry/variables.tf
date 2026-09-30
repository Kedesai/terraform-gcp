# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where Artifact Registry repositories are created."
  type        = string
}


# -----------------------------------------------------------------------------
# Artifact Registry Repository Definitions
#
# The reusable module accepts a map so callers can create one or more
# repositories.
#
# The Terraform map key is only a logical identifier.
#
# repository_id represents the actual Artifact Registry repository name.
# -----------------------------------------------------------------------------

variable "repositories" {
  description = "Map of Artifact Registry repositories to create."

  type = map(object({

    # -------------------------------------------------------------------------
    # Basic Repository Configuration
    # -------------------------------------------------------------------------

    repository_id = string
    location      = string
    format        = string

    description = optional(string)
    labels      = optional(map(string), {})


    # -------------------------------------------------------------------------
    # Customer-Managed Encryption Key
    #
    # Leave null to use the default encryption behavior.
    #
    # When provided, this must contain the Cloud KMS Crypto Key reference used
    # by Artifact Registry.
    # -------------------------------------------------------------------------

    kms_key_name = optional(string)


    # -------------------------------------------------------------------------
    # Docker Repository Configuration
    #
    # immutable_tags applies to Docker repositories.
    #
    # When enabled, an image tag cannot be moved to another image digest.
    # -------------------------------------------------------------------------

    immutable_tags = optional(bool, false)

  }))

  default = {}


  # ---------------------------------------------------------------------------
  # Repository Format Validation
  #
  # These formats cover the package types we currently want our reusable
  # platform module to expose.
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      contains(
        [
          "DOCKER",
          "MAVEN",
          "NPM",
          "PYTHON",
          "APT",
          "YUM",
          "GO",
          "GENERIC"
        ],
        upper(repository.format)
      )
    ])

    error_message = "Repository format must be DOCKER, MAVEN, NPM, PYTHON, APT, YUM, GO, or GENERIC."
  }
}


# -----------------------------------------------------------------------------
# Repository-Level IAM
#
# IAM access is optional.
#
# The repository property references a logical key in var.repositories.
#
# Example:
#
# repository_iam_bindings = {
#   application_reader = {
#     repository = "docker"
#     role       = "roles/artifactregistry.reader"
#
#     members = [
#       "serviceAccount:application@project.iam.gserviceaccount.com"
#     ]
#   }
# }
# -----------------------------------------------------------------------------

variable "repository_iam_bindings" {
  description = "Repository-level IAM role assignments."

  type = map(object({
    repository = string
    role       = string
    members    = set(string)
  }))

  default = {}


  # ---------------------------------------------------------------------------
  # Validate Repository References
  #
  # Every IAM binding must reference a logical repository key that exists in
  # var.repositories.
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for binding in values(var.repository_iam_bindings) :
      contains(keys(var.repositories), binding.repository)
    ])

    error_message = "Each repository IAM binding must reference a logical key defined in var.repositories."
  }
}
