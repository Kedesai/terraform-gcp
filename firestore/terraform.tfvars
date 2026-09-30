# -----------------------------------------------------------------------------
# Firestore Deployment Variables
#
# Environment-specific values should normally be supplied through HCP
# Terraform workspace or project-level variable sets.
#
# Required:
#
# project_id  = "my-gcp-project"
# location_id = "nam5"
#
# Optional:
#
# database_name = "(default)"
# database_type = "FIRESTORE_NATIVE"
#
# concurrency_mode = "PESSIMISTIC"
#
# enable_point_in_time_recovery = true
# delete_protection             = true
# deletion_policy               = "DELETE"
#
# tags = {
#   environment = "dev"
# }
# -----------------------------------------------------------------------------
