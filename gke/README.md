GCP GKE Terraform Module
Reusable Terraform module for creating a Google Kubernetes Engine cluster with separately managed node pools.

Features
Regional or zonal GKE cluster
Existing VPC and subnet integration
VPC-native Pod and Service networking
Private GKE nodes by default
Optional private control-plane endpoint
Control-plane authorized networks
Release-channel configuration
Workload Identity Federation for GKE
Shielded GKE nodes
Network policy
Intranode visibility configuration
Kubernetes Secret encryption using optional Cloud KMS CMEK
Recurring maintenance window
Separately managed node pools
Node-pool autoscaling
Node auto-repair and auto-upgrade
Surge-upgrade configuration
Dedicated node service account
Node labels, metadata, tags, and taints
Optional Spot node pools
Sensitive control-plane outputs
Structure
gke/
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── README.md
A locals.tf file is not required because no additional data transformation is currently needed.

Module Boundaries
This module does not create:

GCP projects
VPC networks
Subnets
Secondary IP ranges
Cloud Router
Cloud NAT
Service accounts
IAM role assignments
KMS keys
Artifact Registry repositories
Kubernetes workloads
Those resources must be supplied by separate reusable modules or by the foundation and landing-zone layers.

Basic Private GKE Cluster
module "gke" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/gke"

  project_id = var.project_id

  cluster_name = "platform-gke"
  location     = "us-central1"

  network    = var.network_self_link
  subnetwork = var.subnetwork_self_link

  cluster_secondary_range_name  = "gke-pods"
  services_secondary_range_name = "gke-services"

  enable_private_nodes    = true
  enable_private_endpoint = false

  master_ipv4_cidr_block = "172.16.0.0/28"

  node_pools = {
    system = {
      name = "system"

      machine_type = "e2-standard-4"
      disk_size_gb = 100
      disk_type    = "pd-balanced"

      service_account_email = var.node_service_account_email

      autoscaling = {
        enabled   = true
        min_count = 1
        max_count = 3
      }
    }
  }
}
Network Composition
VPC module
    |
    +-- network_self_link
    +-- subnet_self_links["gke"]
    +-- secondary ranges
                 |
                 v
             GKE module
                 |
                 +-- cluster
                 +-- node pools
The subnet must already contain the secondary ranges supplied through:

cluster_secondary_range_name
services_secondary_range_name
Private Cluster Behavior
Defaults:

enable_private_nodes       = true
enable_private_endpoint    = false
master_ipv4_cidr_block     = "172.16.0.0/28"
master_global_access_enabled = false
Private nodes do not receive external IP addresses.

A networking solution such as Cloud NAT may be required when private nodes need outbound access to external endpoints. Cloud Router and Cloud NAT remain outside this module.

Workload Identity Federation for GKE
Workload Identity Federation is enabled by default:

enable_workload_identity = true
The generated workload pool is:

PROJECT_ID.svc.id.goog
Kubernetes service-account mappings and Google IAM bindings are managed separately.

Control-Plane Authorized Networks
master_authorized_networks = [
  {
    cidr_block   = "10.0.0.0/8"
    display_name = "corporate-network"
  }
]
When the list is empty, the module omits the authorized-networks block.

Release Channel
Default:

release_channel = "REGULAR"
Supported values:

RAPID
REGULAR
STABLE
EXTENDED
UNSPECIFIED
GKE Database Encryption with CMEK
database_encryption_key_id = var.kms_key_id
The supplied value must be a fully qualified Cloud KMS Crypto Key identifier.

Required KMS IAM permission for the appropriate Google service identity must be configured separately.

Node Service Account
node_pools = {
  system = {
    name = "system"

    service_account_email = var.node_service_account_email
  }
}
The service account must be created and authorized independently.

Default OAuth scopes are:

[
  "https://www.googleapis.com/auth/cloud-platform"
]
IAM roles remain the primary authorization mechanism.

Autoscaling Node Pool
node_pools = {
  application = {
    name         = "application"
    machine_type = "e2-standard-4"

    autoscaling = {
      enabled   = true
      min_count = 1
      max_count = 5
    }
  }
}
Spot Node Pool
node_pools = {
  batch = {
    name         = "batch"
    machine_type = "e2-standard-4"
    spot         = true

    autoscaling = {
      enabled   = true
      min_count = 0
      max_count = 10
    }

    taints = [
      {
        key    = "workload"
        value  = "batch"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}
Node-Pool Upgrade Strategy
node_pools = {
  system = {
    name = "system"

    auto_repair  = true
    auto_upgrade = true

    max_surge       = 1
    max_unavailable = 0
  }
}
Shielded Nodes
Cluster-level Shielded GKE nodes default to:

enable_shielded_nodes = true
Node-pool defaults:

enable_secure_boot          = false
enable_integrity_monitoring = true
Maintenance Window
maintenance_start_time = "2026-10-04T06:00:00Z"
maintenance_end_time   = "2026-10-04T10:00:00Z"
maintenance_recurrence = "FREQ=WEEKLY;BYDAY=SU"
All three values must be supplied for the recurring window to be generated.

Deletion Protection
The cluster defaults to:

deletion_protection = true
Before intentionally destroying the cluster, set:

deletion_protection = false
Apply that change before running the destroy operation.

HCP Terraform Composition
The reusable module does not contain HCP Terraform workspace logic.

The GKE caller can retrieve foundation values using tfe_outputs:

Foundation workspace
    |
    +-- network_self_link
    +-- subnet_self_link
    +-- Pod range name
    +-- Service range name
                 |
                 v
            GKE caller
                 |
                 v
        Reusable GKE module
This keeps HCP orchestration in the caller and GCP implementation in the reusable module.

Outputs
The module exposes:

cluster_id
cluster_name
cluster_location
cluster_self_link
cluster_endpoint
cluster_ca_certificate
network
subnetwork
cluster_secondary_range_name
services_secondary_range_name
workload_identity_pool
node_pool_ids
node_pool_names
node_pool_instance_group_urls
Cluster endpoint and CA certificate outputs are marked sensitive.

Validation
terraform fmt -recursive
terraform init
terraform validate
terraform plan
Design Principles
Networking is consumed rather than recreated
Node service accounts are consumed rather than recreated
KMS keys are consumed rather than recreated
Artifact Registry remains independent
Node pools are managed separately from the cluster
Private nodes are enabled by default
Workload Identity Federation is enabled by default
Shielded nodes are enabled by default
Deletion protection is enabled by default
Optional features are caller-controlled
HCP workspace orchestration belongs in the caller layer.


Important deployment dependencies

Before applying this module, the caller must provide:
Required
├── GCP project
├── VPC network
├── Subnet
├── Pod secondary range
└── Service secondary range

Strongly recommended
└── Dedicated node service account

Optional
├── KMS key for Kubernetes Secret encryption
├── Master authorized networks
└── Maintenance window