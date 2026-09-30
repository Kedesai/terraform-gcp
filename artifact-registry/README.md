GCP Artifact Registry Terraform Module
Reusable Terraform module for creating Google Artifact Registry repositories with optional CMEK encryption and repository-level IAM access.

Features
Create one or more Artifact Registry repositories
Docker repositories
Maven repositories
npm repositories
Python repositories
APT repositories
YUM repositories
Go repositories
Generic repositories
Docker immutable-tag configuration
Optional customer-managed encryption key
Repository labels
Optional repository-level IAM
Reusable outputs
Repository Structure
artifact-registry/
├── versions.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
└── README.md
Basic Docker Repository
module "artifact_registry" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/artifact-registry"

  project_id = var.project_id

  repositories = {
    docker = {
      repository_id = "application-images"
      location      = "us-central1"
      format        = "DOCKER"
    }
  }
}
Docker Repository with Immutable Tags
repositories = {
  docker = {
    repository_id = "application-images"
    location      = "us-central1"
    format        = "DOCKER"

    immutable_tags = true
  }
}
Repository with CMEK
repositories = {
  docker = {
    repository_id = "application-images"
    location      = "us-central1"
    format        = "DOCKER"

    kms_key_name = var.kms_key_id
  }
}
The required KMS IAM permission must also be configured for the Artifact Registry service identity when using CMEK.

Repository IAM
repository_iam_bindings = {
  application_reader = {
    repository = "docker"
    role       = "roles/artifactregistry.reader"

    members = [
      "serviceAccount:application@my-project.iam.gserviceaccount.com"
    ]
  }
}
The repository property references the logical map key under repositories, not the actual repository ID.

Multiple Repositories
repositories = {
  containers = {
    repository_id = "application-images"
    location      = "us-central1"
    format        = "DOCKER"
  }

  libraries = {
    repository_id = "java-libraries"
    location      = "us-central1"
    format        = "MAVEN"
  }

  python = {
    repository_id = "python-packages"
    location      = "us-central1"
    format        = "PYTHON"
  }
}
Outputs
The module exposes:

repository_ids
repository_names
repository_locations
repository_iam_members
Design Principles
Provider configuration belongs to the caller
Authentication is external to the reusable module
KMS keys are created outside Artifact Registry
Service accounts are created outside Artifact Registry
Repository IAM is optional
Multiple repositories are supported
The caller decides which reusable capabilities to consume.