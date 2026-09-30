GCP Private Service Access Terraform Module
Reusable Terraform module for creating a Private Service Access allocated range and Service Networking connection for an existing Google Cloud VPC.

Architecture
Existing VPC
     |
     v
Allocated VPC Peering Range
     |
     v
Service Networking Connection
     |
     v
Supported Google-Managed Services
Features
Existing VPC integration
Global internal VPC peering range
Automatic address allocation
Explicit address allocation
Configurable prefix length
Service Networking connection
Protected connection deletion by default
Optional existing-connection range update
Optional custom-route import
Optional custom-route export
Stable outputs for downstream Terraform workspaces
Directory Structure
private-service-access/
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── README.md
A locals.tf file is not required because the module does not perform additional normalization or transformation.

Module Boundaries
This module creates:

google_compute_global_address
google_service_networking_connection
google_compute_network_peering_routes_config
The route-configuration resource is optional.

This module does not create:

GCP projects
VPC networks
Subnets
Cloud SQL instances
Google Cloud API enablement
IAM roles or bindings
DNS resources
Prerequisites
The following must already exist:

A Google Cloud project
An existing VPC network
Required Google Cloud APIs
Appropriate permissions for the Terraform execution identity
The project or foundation layer should enable:

servicenetworking.googleapis.com
Basic Usage
module "private_service_access" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/private-service-access"

  project_id = var.project_id

  network_id   = var.network_id
  network_name = var.network_name

  allocated_range_name = "google-managed-services-platform"
  prefix_length        = 16
}
Automatic Address Allocation
Leave address as null and supply the prefix length:

address       = null
prefix_length = 16
Google Cloud selects the address range.

The resulting allocation must not overlap existing or planned network ranges.

Explicit Address Allocation
module "private_service_access" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/private-service-access"

  project_id = var.project_id

  network_id   = var.network_id
  network_name = var.network_name

  allocated_range_name = "google-managed-services-platform"

  address       = "10.240.0.0"
  prefix_length = 16
}
Allocated Range
The module creates the equivalent of:

purpose      = "VPC_PEERING"
address_type = "INTERNAL"
The allocated range name is supplied to the Service Networking connection through reserved_peering_ranges.

Service Networking Connection
The default service producer is:

service = "servicenetworking.googleapis.com"
The module connects the existing consumer VPC to the service-producer network.

Existing Connection Update
Optional:

update_on_creation_fail = true
This allows the Service Networking resource to attempt an update of the reserved peering ranges if creation fails because a connection already exists.

Enable this only when handling an existing connection is intentional.

Custom Route Exchange
Custom-route exchange is disabled by default:

import_custom_routes = false
export_custom_routes = false
It can be enabled explicitly:

import_custom_routes = true
export_custom_routes = true
The optional route configuration uses:

The existing VPC network name
The peering name returned by the Service Networking connection
Connection Deletion Policy
The module protects the connection by default:

deletion_policy = "PREVENT"
Supported module values are:

PREVENT
ABANDON
DELETE
PREVENT
Prevents Terraform from deleting the Service Networking connection.

This is the recommended default for a connection potentially shared by multiple managed services.

ABANDON
Removes the connection from Terraform management without deleting the connection through the API.

DELETE
Allows Terraform to request normal deletion of the Service Networking connection.

Dependent managed-service resources should be removed before deleting the connection.

Safe Teardown Sequence
Recommended teardown flow:

1. Remove dependent managed-service resources
2. Confirm the PSA connection is no longer required
3. Change deletion_policy from PREVENT to DELETE
4. Apply the deletion-policy change
5. Remove the PSA deployment
6. Run the final apply or destroy
If the connection must remain but Terraform management should stop, use:

deletion_policy = "ABANDON"
instead of deleting the connection.

Cloud SQL Composition
VPC Module
    |
    +-- network_id
    +-- network_name
             |
             v
Private Service Access Module
    |
    +-- allocated_ip_range_name
    +-- connection_network
    +-- connection_peering
             |
             v
Cloud SQL Module
Example:

module "cloud_sql" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/cloud-sql"

  project_id = var.project_id

  instance_name    = "platform-postgres"
  region           = "us-central1"
  database_version = "POSTGRES_15"
  tier             = "db-custom-2-7680"

  private_network = (
    module.private_service_access.connection_network
  )

  allocated_ip_range = (
    module.private_service_access.allocated_ip_range_name
  )
}
Shared VPC Consideration
Private Service Access resources are associated with the project that owns the VPC network.

In a Shared VPC architecture, the caller should supply the project containing the VPC and PSA resources.

The current variable is:

project_id
A future landing-zone implementation can make the network-project distinction explicit if required.

Outputs
The module exposes:

allocated_ip_range_id
allocated_ip_range_name
allocated_ip_range_address
allocated_ip_range_prefix_length
allocated_ip_range_self_link
connection_network
connection_service
connection_peering
reserved_peering_ranges
Validation
Before releasing changes:

terraform fmt -recursive
terraform init
terraform validate
terraform plan
Design Principles
VPC creation remains outside this module
PSA remains a shared networking capability
Managed services consume PSA rather than recreate it
API enablement remains in the project or foundation layer
IAM remains outside the module
Destructive connection deletion is prevented by default
Downstream services consume stable module outputs