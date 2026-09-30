GCP Cloud SQL Terraform Module
Reusable Terraform module for deploying Google Cloud SQL instances and databases.

Features
PostgreSQL support
MySQL support
SQL Server support
Private IP connectivity
Optional public IPv4
Existing VPC integration
Existing Private Service Access range integration
Configurable SSL mode
Authorized public networks
Zonal or regional availability
Configurable storage
Disk autoresize
Automated backups
Backup retention
Point-in-time recovery for supported engines
Transaction-log retention
Maintenance windows
Database flags
Optional Cloud KMS CMEK
Instance deletion protection
Multiple databases
Directory Structure
cloud-sql/
├── versions.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
└── README.md
Basic PostgreSQL Example
module "cloud_sql" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/cloud-sql"

  project_id = var.project_id

  instance_name    = "platform-postgres"
  region           = "us-central1"
  database_version = "POSTGRES_15"
  tier             = "db-custom-2-7680"

  private_network = var.network_self_link

  databases = {
    application = {
      name = "application"
    }
  }
}
Private Networking
The module does not create the networking foundation required for private Cloud SQL.

The expected architecture is:

VPC
 |
 v
Private Service Access Range
 |
 v
Service Networking Connection
 |
 v
Cloud SQL
The caller supplies the existing VPC:

private_network = var.network_self_link
and can optionally supply the allocated range:

allocated_ip_range = "google-managed-services-platform"
At least one connectivity mechanism must be configured:

private_network
or:

ipv4_enabled = true
Our platform callers should normally use private networking.

Private Service Access
Private Service Access is intentionally outside this module.

This module does not create:

google_compute_global_address
google_service_networking_connection
That functionality belongs to the networking/foundation layer.

The Cloud SQL caller can later consume the network and PSA outputs using tfe_outputs.

Public IP
Public IPv4 is disabled by default:

ipv4_enabled = false
If public IPv4 is intentionally required:

ipv4_enabled = true
Authorized networks can then be supplied:

authorized_networks = [
  {
    name  = "corporate"
    value = "203.0.113.0/24"
  }
]
SSL
Optional SSL enforcement is supported:

ssl_mode = "ENCRYPTED_ONLY"
Supported module values are:

ALLOW_UNENCRYPTED_AND_ENCRYPTED
ENCRYPTED_ONLY
TRUSTED_CLIENT_CERTIFICATE_REQUIRED
The final option is not used with SQL Server.

High Availability
The default is:

availability_type = "ZONAL"
Regional availability can be selected:

availability_type = "REGIONAL"
Storage
Defaults:

disk_type       = "PD_SSD"
disk_size_gb    = 20
disk_autoresize = true
An optional autoresize limit can be supplied:

disk_autoresize_limit = 500
Automated Backups
Automated backups are enabled by default:

backup_enabled    = true
backup_start_time = "03:00"
retained_backups  = 7
The backup configuration is omitted when:

backup_enabled = false
Point-in-Time Recovery
The module conditionally handles PITR based on the configured database engine.

For PostgreSQL and SQL Server:

point_in_time_recovery_enabled = true
can be supplied through the backup configuration.

The module does not pass this particular provider property for MySQL.

Transaction-Log Retention
Optional:

transaction_log_retention_days = 7
This module currently constrains the value to:

1 through 7 days
The narrower range intentionally keeps the generic reusable interface consistent across the supported configuration represented by the module.

Maintenance Window
Both values must be supplied:

maintenance_window_day  = 7
maintenance_window_hour = 5
The module creates no maintenance-window block unless both values exist.

Database Flags
Example:

database_flags = {
  log_connections = "on"
}
Valid database flags depend on the selected database engine and version.

Multiple Databases
databases = {
  application = {
    name = "application"
  }

  reporting = {
    name = "reporting"
  }
}
Optional database properties:

databases = {
  application = {
    name             = "application"
    charset          = "UTF8"
    collation        = "en_US.UTF8"
    deletion_policy  = "DELETE"
  }
}
The module supports database deletion policies:

DELETE
ABANDON
Customer-Managed Encryption
The Cloud SQL module consumes an existing Cloud KMS key.

Example:

encryption_key_name = var.crypto_key_id
The module does not create:

KMS key
KMS key ring
KMS IAM
Those remain external dependencies.

The future Cloud SQL caller can retrieve the key through tfe_outputs.

Deletion Protection
Deletion protection is enabled by default:

deletion_protection = true
Before intentionally destroying the instance, set:

deletion_protection = false
and apply that change before destroying the instance.

Database Users
Database users are intentionally not managed by this module.

The initial module does not accept:

database username
database password
root password
This prevents database credential lifecycle from being mixed into the infrastructure module interface.

Database identity and Secret Manager integration will be handled separately.

External Dependencies
Depending on the selected features, this module can consume:

VPC network
Private Service Access range
Service Networking connection
Cloud KMS CryptoKey
It does not create those foundation resources.

Module Boundary
Networking/Foundation
       |
       +-- VPC
       +-- PSA range
       +-- Service Networking
               |
               v
        Cloud SQL Module
         |           |
         v           v
      Instance    Databases
Outputs
The module exposes:

instance_id
instance_name
connection_name
database_version
region
private_ip_address
public_ip_address
database_ids
database_names
Validation
terraform fmt -recursive
terraform init
terraform validate
terraform plan
Design Principles
Provider configuration belongs to the caller
Authentication remains outside the reusable module
Private networking is preferred
Networking foundation remains outside Cloud SQL
KMS remains outside Cloud SQL
IAM remains outside Cloud SQL
Database credentials remain outside Cloud SQL
Deletion protection is enabled by default
Backups are enabled by default
Engine-specific behavior is handled explicitly
Multiple databases are supported without duplicating instances