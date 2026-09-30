# -----------------------------------------------------------------------------
# Database Engine Detection
#
# Used to conditionally configure engine-specific Cloud SQL functionality.
# -----------------------------------------------------------------------------

locals {
  is_postgres = startswith(
    upper(var.database_version),
    "POSTGRES_"
  )

  is_mysql = startswith(
    upper(var.database_version),
    "MYSQL_"
  )

  is_sqlserver = startswith(
    upper(var.database_version),
    "SQLSERVER_"
  )
}
