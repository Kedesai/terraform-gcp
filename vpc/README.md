# GCP VPC Terraform Module

Reusable Terraform module for creating or consuming a Google Cloud VPC network.

## Features

- Create a custom-mode VPC
- Consume an existing VPC
- Create multiple regional subnets
- Private Google Access
- Secondary subnet IP ranges
- GKE-ready Pod and Service ranges
- Optional VPC flow logging
- Configurable routing mode
- Configurable MTU
- Optional deletion of default routes
- Outputs designed for composition with other Terraform modules

## Example

```hcl
module "vpc" {
  source = "git::ssh://git@github.com/Kedesai/terraform.git//gcp/vpc"

  project_id   = var.project_id
  create_vpc   = true
  network_name = "platform-vpc"

  routing_mode = "GLOBAL"

  subnets = {
    gke = {
      name          = "gke-subnet"
      region        = var.region
      ip_cidr_range = "10.10.0.0/20"

      private_ip_google_access = true

      secondary_ip_ranges = {
        pods = {
          range_name    = "gke-pods"
          ip_cidr_range = "10.20.0.0/16"
        }

        services = {
          range_name    = "gke-services"
          ip_cidr_range = "10.30.0.0/20"
        }
      }

      log_config = {
        aggregation_interval = "INTERVAL_5_SEC"
        flow_sampling        = 0.5
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  }
}

GCP VPC Terraform Module
Reusable Terraform module for creating or consuming a Google Cloud VPC network.

Features
Create a custom-mode VPC
Consume an existing VPC
Create multiple regional subnets
Private Google Access
Secondary subnet IP ranges
GKE-ready Pod and Service ranges
Optional VPC flow logging
Configurable routing mode
Configurable MTU
Optional deletion of default routes
Outputs designed for composition with other Terraform modules
Example
module "vpc" {
  source = "git::ssh://git@github.com/Kedesai/terraform.git//gcp/vpc"

  project_id   = var.project_id
  create_vpc   = true
  network_name = "platform-vpc"

  routing_mode = "GLOBAL"

  subnets = {
    gke = {
      name          = "gke-subnet"
      region        = var.region
      ip_cidr_range = "10.10.0.0/20"

      private_ip_google_access = true

      secondary_ip_ranges = {
        pods = {
          range_name    = "gke-pods"
          ip_cidr_range = "10.20.0.0/16"
        }

        services = {
          range_name    = "gke-services"
          ip_cidr_range = "10.30.0.0/20"
        }
      }

      log_config = {
        aggregation_interval = "INTERVAL_5_SEC"
        flow_sampling        = 0.5
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  }
}