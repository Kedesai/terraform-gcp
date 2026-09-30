GCP Pub/Sub Terraform Module
Reusable Terraform module for creating Google Cloud Pub/Sub topics, pull subscriptions, dead-letter routing, retry configuration, and resource-level IAM memberships.

Features
Creates one or more Pub/Sub topics
Creates one or more pull subscriptions
Topic-level message retention
Subscription-level message retention
Retained acknowledged messages
Configurable acknowledgment deadline
Subscription expiration policy
Retry policy
Subscription filters
Message ordering
Dead-letter topics
Optional topic CMEK
Optional message-storage region restrictions
Topic-level IAM
Subscription-level IAM
Reusable topic and subscription outputs
Structure
pubsub/
├── versions.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
└── README.md
Basic Topic and Subscription
module "pubsub" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/pubsub"

  project_id = var.project_id

  topics = {
    events = {
      name = "application-events"
    }
  }

  subscriptions = {
    application = {
      name  = "application-events-subscription"
      topic = "events"
    }
  }
}
The subscription topic property references the logical key events, not the actual topic name.

Topic with CMEK
topics = {
  events = {
    name         = "application-events"
    kms_key_name = var.kms_key_id
  }
}
Required KMS permissions for the Pub/Sub service identity must be configured separately.

Retention and Retry Policy
subscriptions = {
  application = {
    name  = "application-events-subscription"
    topic = "events"

    ack_deadline_seconds       = 30
    message_retention_duration = "604800s"
    retain_acked_messages      = true

    retry_policy = {
      minimum_backoff = "10s"
      maximum_backoff = "600s"
    }
  }
}
Dead-Letter Topic
topics = {
  events = {
    name = "application-events"
  }

  dead_letter = {
    name = "application-events-dead-letter"
  }
}

subscriptions = {
  application = {
    name  = "application-events-subscription"
    topic = "events"

    dead_letter_policy = {
      dead_letter_topic     = "dead_letter"
      max_delivery_attempts = 10
    }
  }
}
The dead-letter topic must be defined under topics.

Required Pub/Sub service-agent IAM permissions must be configured separately.

Topic Publisher IAM
topic_iam_bindings = {
  application_publisher = {
    topic = "events"
    role  = "roles/pubsub.publisher"

    members = [
      "serviceAccount:publisher@my-project.iam.gserviceaccount.com"
    ]
  }
}
Subscription Subscriber IAM
subscription_iam_bindings = {
  application_subscriber = {
    subscription = "application"
    role         = "roles/pubsub.subscriber"

    members = [
      "serviceAccount:subscriber@my-project.iam.gserviceaccount.com"
    ]
  }
}
Message Storage Policy
topics = {
  events = {
    name = "application-events"

    allowed_persistence_regions = [
      "us-central1",
      "us-east1"
    ]

    enforce_in_transit = true
  }
}
Outputs
The module exposes:

topic_ids
topic_names
subscription_ids
subscription_names
subscription_topics
topic_iam_members
subscription_iam_members
All resource outputs are keyed by the logical keys supplied in the input maps.

Module Boundaries
This module does not create:

Service accounts
Project-level IAM roles
KMS keys
KMS key IAM
Pub/Sub service-agent IAM
Push endpoints
Application workloads
Those capabilities remain separate reusable modules or orchestration concerns.

Design Principles
Provider configuration belongs to the caller
Authentication remains outside the reusable module
CMEK remains optional
IAM remains optional
Topics and subscriptions are referenced using stable logical keys
Resource-level IAM uses individual membership resources
The caller selects only the capabilities it needs
Dead-letter infrastructure and service-agent authorization remain distinct

Composition

KMS module
    |
    +-- crypto_key_id
               |
               v
Service Account module ---> Pub/Sub module
    |                           |
    +-- member                  +-- Topic
                                +-- Subscription
                                +-- Retry policy
                                +-- Dead-letter topic
                                +-- Resource IAM