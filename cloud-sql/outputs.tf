# -----------------------------------------------------------------------------
# Cloud SQL Instance Outputs
# -----------------------------------------------------------------------------

output "instance_id" {
  description = "Cloud SQL instance resource ID."
  value       = google_sql_database_instance.this.id
}

output "instance_name" {
  description = "Cloud SQL instance name."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "Cloud SQL connection name."
  value       = google_sql_database_instance.this.connection_name
}

output "database_version" {
  description = "Cloud SQL database engine/version."
  value       = google_sql_database_instance.this.database_version
}

output "region" {
  description = "Cloud SQL instance region."
  value       = google_sql_database_instance.this.region
}


# -----------------------------------------------------------------------------
# Network Outputs
# -----------------------------------------------------------------------------

output "private_ip_address" {
  description = "Private IP address assigned to the Cloud SQL instance."
  value       = google_sql_database_instance.this.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address assigned to the instance when enabled."
  value       = google_sql_database_instance.this.public_ip_address
}


# -----------------------------------------------------------------------------
# Database Outputs
# -----------------------------------------------------------------------------

output "database_ids" {
  description = "Map of Cloud SQL database resource IDs."

  value = {
    for key, database in google_sql_database.this :
    key => database.id
  }
}

output "database_names" {
  description = "Map of database names."

  value = {
    for key, database in google_sql_database.this :
    key => database.name
  }
}
