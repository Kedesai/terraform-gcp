# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where Pub/Sub resources are created."
  type        = string
}


# -----------------------------------------------------------------------------
# Pub/Sub Topic Definitions
#
# The module accepts a map so callers can create one or more topics.
#
# The Terraform map key is the logical identifier used by subscriptions,
# IAM bindings, and module outputs.
#
# The name property is the actual Pub/Sub topic name in GCP.
# -----------------------------------------------------------------------------

variable "topics" {
  description = "Map of Pub/Sub topics to create."

  type = map(object({
    name = string

    labels = optional(map(string), {})

    # Retains topic messages for the supplied duration.
    # Leave null when topic-level message retention is not required.
    message_retention_duration = optional(string)

    # Optional fully qualified Cloud KMS Crypto Key ID.
    kms_key_name = optional(string)

    # Optional message-storage restrictions.
    allowed_persistence_regions = optional(list(string), [])
    enforce_in_transit          = optional(bool, false)
  }))

  default = {}
}


# -----------------------------------------------------------------------------
# Pub/Sub Subscription Definitions
#
# This first reusable version manages pull subscriptions.
#
# The topic property references a logical key in var.topics rather than
# duplicating the actual topic name or resource ID.
# -----------------------------------------------------------------------------

variable "subscriptions" {
  description = "Map of Pub/Sub pull subscriptions to create."

  type = map(object({
    name  = string
    topic = string

    labels = optional(map(string), {})

    ack_deadline_seconds       = optional(number, 20)
    message_retention_duration = optional(string, "604800s")
    retain_acked_messages      = optional(bool, false)

    enable_message_ordering = optional(bool, false)
    filter                  = optional(string)

    # Leave null to omit the subscription expiration policy.
    expiration_ttl = optional(string)

    # Retry policy is generated only when this object is supplied.
    retry_policy = optional(object({
      minimum_backoff = optional(string, "10s")
      maximum_backoff = optional(string, "600s")
    }))

    # dead_letter_topic references another logical key in var.topics.
    dead_letter_policy = optional(object({
      dead_letter_topic     = string
      max_delivery_attempts = optional(number, 5)
    }))
  }))

  default = {}


  # ---------------------------------------------------------------------------
  # Topic Reference Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for subscription in values(var.subscriptions) :
      contains(keys(var.topics), subscription.topic)
    ])

    error_message = "Every subscription must reference a logical topic key defined in var.topics."
  }


  # ---------------------------------------------------------------------------
  # Acknowledgment Deadline Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for subscription in values(var.subscriptions) :
      subscription.ack_deadline_seconds >= 10 &&
      subscription.ack_deadline_seconds <= 600
    ])

    error_message = "ack_deadline_seconds must be between 10 and 600."
  }


  # ---------------------------------------------------------------------------
  # Dead-Letter Topic Reference Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for subscription in values(var.subscriptions) :
      subscription.dead_letter_policy == null ||
      contains(
        keys(var.topics),
        subscription.dead_letter_policy.dead_letter_topic
      )
    ])

    error_message = "Every dead-letter topic must reference a logical topic key defined in var.topics."
  }


  # ---------------------------------------------------------------------------
  # Dead-Letter Delivery Attempt Validation
  # ---------------------------------------------------------------------------

  validation {
    condition = alltrue([
      for subscription in values(var.subscriptions) :
      subscription.dead_letter_policy == null ||
      (
        subscription.dead_letter_policy.max_delivery_attempts >= 5 &&
        subscription.dead_letter_policy.max_delivery_attempts <= 100
      )
    ])

    error_message = "max_delivery_attempts must be between 5 and 100."
  }
}


# -----------------------------------------------------------------------------
# Topic-Level IAM
#
# The topic property references a logical key in var.topics.
#
# Examples:
#
# roles/pubsub.publisher
# roles/pubsub.viewer
# -----------------------------------------------------------------------------

variable "topic_iam_bindings" {
  description = "Topic-level IAM role assignments."

  type = map(object({
    topic   = string
    role    = string
    members = set(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for binding in values(var.topic_iam_bindings) :
      contains(keys(var.topics), binding.topic)
    ])

    error_message = "Every topic IAM binding must reference a logical topic key defined in var.topics."
  }
}


# -----------------------------------------------------------------------------
# Subscription-Level IAM
#
# The subscription property references a logical key in var.subscriptions.
#
# Examples:
#
# roles/pubsub.subscriber
# roles/pubsub.viewer
# -----------------------------------------------------------------------------

variable "subscription_iam_bindings" {
  description = "Subscription-level IAM role assignments."

  type = map(object({
    subscription = string
    role         = string
    members      = set(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for binding in values(var.subscription_iam_bindings) :
      contains(keys(var.subscriptions), binding.subscription)
    ])

    error_message = "Every subscription IAM binding must reference a logical subscription key defined in var.subscriptions."
  }
}
