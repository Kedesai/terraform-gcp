# -----------------------------------------------------------------------------
# Google Cloud Pub/Sub
#
# This reusable module manages:
#
# - Pub/Sub topics
# - Topic message retention
# - Topic CMEK encryption
# - Topic message-storage policies
# - Pull subscriptions
# - Subscription message retention
# - Subscription acknowledgment settings
# - Subscription filtering
# - Message ordering
# - Subscription expiration policies
# - Retry policies
# - Dead-letter policies
# - Topic-level IAM memberships
# - Subscription-level IAM memberships
#
# This module intentionally does NOT create:
#
# - Service accounts
# - Project-level IAM roles
# - Cloud KMS keys
# - KMS IAM permissions
# - Pub/Sub service-agent IAM permissions
# - Application workloads
#
# Those capabilities remain separate reusable modules or orchestration
# responsibilities.
# -----------------------------------------------------------------------------


# =============================================================================
# PUB/SUB TOPICS
# =============================================================================

# -----------------------------------------------------------------------------
# Pub/Sub Topics
#
# Each entry in var.topics creates one Pub/Sub topic.
#
# Example:
#
# topics = {
#   events = {
#     name = "application-events"
#   }
#
#   dead_letter = {
#     name = "application-events-dead-letter"
#   }
# }
#
# "events" and "dead_letter" are logical Terraform keys.
#
# The actual GCP topic names come from each entry's name property.
# -----------------------------------------------------------------------------

resource "google_pubsub_topic" "this" {
  for_each = var.topics

  project = var.project_id
  name    = each.value.name

  # ---------------------------------------------------------------------------
  # Topic Labels
  # ---------------------------------------------------------------------------

  labels = each.value.labels


  # ---------------------------------------------------------------------------
  # Topic Message Retention
  #
  # Pub/Sub can retain messages directly at the topic level.
  #
  # When message_retention_duration is null, topic-level retention is not
  # explicitly configured by this module.
  # ---------------------------------------------------------------------------

  message_retention_duration = each.value.message_retention_duration


  # ---------------------------------------------------------------------------
  # Customer-Managed Encryption Key
  #
  # kms_key_name accepts an optional fully qualified Cloud KMS Crypto Key.
  #
  # Example:
  #
  # projects/PROJECT_ID/locations/global/keyRings/RING/cryptoKeys/KEY
  #
  # Supplying the Crypto Key does not grant the Pub/Sub service identity
  # permission to use it.
  #
  # KMS IAM is intentionally managed separately.
  # ---------------------------------------------------------------------------

  kms_key_name = each.value.kms_key_name


  # ---------------------------------------------------------------------------
  # Message Storage Policy
  #
  # A message_storage_policy block is generated only when at least one
  # allowed persistence region has been configured.
  #
  # This keeps the default topic configuration simple while still allowing
  # callers to restrict where Pub/Sub message data is stored.
  # ---------------------------------------------------------------------------

  dynamic "message_storage_policy" {
    for_each = length(
      each.value.allowed_persistence_regions
    ) > 0 ? [1] : []

    content {
      allowed_persistence_regions = (
        each.value.allowed_persistence_regions
      )

      enforce_in_transit = (
        each.value.enforce_in_transit
      )
    }
  }
}


# =============================================================================
# PUB/SUB SUBSCRIPTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Pub/Sub Pull Subscriptions
#
# Each entry in var.subscriptions creates one Pub/Sub subscription.
#
# The subscription does not contain the actual GCP topic name.
#
# Instead, it references a logical topic key from var.topics.
#
# Example:
#
# subscriptions = {
#   application = {
#     name  = "application-events-subscription"
#     topic = "events"
#   }
# }
#
# Terraform resolves:
#
#   "events"
#
# into:
#
#   google_pubsub_topic.this["events"].id
#
# This prevents callers from duplicating topic resource IDs.
# -----------------------------------------------------------------------------

resource "google_pubsub_subscription" "this" {
  for_each = var.subscriptions

  project = var.project_id

  name = each.value.name

  topic = google_pubsub_topic.this[
    each.value.topic
  ].id


  # ---------------------------------------------------------------------------
  # Subscription Labels
  # ---------------------------------------------------------------------------

  labels = each.value.labels


  # ---------------------------------------------------------------------------
  # Acknowledgment Deadline
  #
  # Controls the amount of time Pub/Sub waits for the subscriber to
  # acknowledge delivery before the message becomes eligible for redelivery.
  # ---------------------------------------------------------------------------

  ack_deadline_seconds = (
    each.value.ack_deadline_seconds
  )


  # ---------------------------------------------------------------------------
  # Subscription Message Retention
  #
  # Controls how long unacknowledged messages remain available to the
  # subscription.
  # ---------------------------------------------------------------------------

  message_retention_duration = (
    each.value.message_retention_duration
  )


  # ---------------------------------------------------------------------------
  # Retain Acknowledged Messages
  #
  # When enabled, acknowledged messages remain retained according to the
  # subscription's message-retention configuration.
  # ---------------------------------------------------------------------------

  retain_acked_messages = (
    each.value.retain_acked_messages
  )


  # ---------------------------------------------------------------------------
  # Message Ordering
  #
  # Enables ordered delivery for messages published with an ordering key.
  # ---------------------------------------------------------------------------

  enable_message_ordering = (
    each.value.enable_message_ordering
  )


  # ---------------------------------------------------------------------------
  # Subscription Filter
  #
  # When supplied, only messages matching the filter are delivered to this
  # subscription.
  #
  # null means no filter is explicitly configured.
  # ---------------------------------------------------------------------------

  filter = each.value.filter


  # ---------------------------------------------------------------------------
  # Expiration Policy
  #
  # Pub/Sub can automatically delete subscriptions after a period of
  # inactivity.
  #
  # No expiration_policy block is created when expiration_ttl is null.
  # ---------------------------------------------------------------------------

  dynamic "expiration_policy" {
    for_each = (
      each.value.expiration_ttl == null
      ? []
      : [each.value.expiration_ttl]
    )

    content {
      ttl = expiration_policy.value
    }
  }


  # ---------------------------------------------------------------------------
  # Retry Policy
  #
  # Controls the exponential backoff applied when message delivery repeatedly
  # fails.
  #
  # No retry_policy block is created unless the caller supplies one.
  # ---------------------------------------------------------------------------

  dynamic "retry_policy" {
    for_each = (
      each.value.retry_policy == null
      ? []
      : [each.value.retry_policy]
    )

    content {
      minimum_backoff = (
        retry_policy.value.minimum_backoff
      )

      maximum_backoff = (
        retry_policy.value.maximum_backoff
      )
    }
  }


  # ---------------------------------------------------------------------------
  # Dead-Letter Policy
  #
  # Messages that cannot be successfully processed can be forwarded to
  # another Pub/Sub topic after repeated delivery attempts.
  #
  # The caller references the logical Terraform key of another topic.
  #
  # Example:
  #
  # dead_letter_policy = {
  #   dead_letter_topic     = "dead_letter"
  #   max_delivery_attempts = 10
  # }
  #
  # Terraform resolves that to the actual topic resource ID.
  #
  # Pub/Sub service-agent IAM permissions required for dead-letter forwarding
  # are intentionally outside this reusable module.
  # ---------------------------------------------------------------------------

  dynamic "dead_letter_policy" {
    for_each = (
      each.value.dead_letter_policy == null
      ? []
      : [each.value.dead_letter_policy]
    )

    content {
      dead_letter_topic = google_pubsub_topic.this[
        dead_letter_policy.value.dead_letter_topic
      ].id

      max_delivery_attempts = (
        dead_letter_policy.value.max_delivery_attempts
      )
    }
  }


  # ---------------------------------------------------------------------------
  # Explicit Topic Dependency
  #
  # The topic attribute already creates an implicit dependency on the selected
  # topic.
  #
  # This explicit dependency makes the intended resource ordering clear when
  # reviewing the module.
  # ---------------------------------------------------------------------------

  depends_on = [
    google_pubsub_topic.this
  ]
}


# =============================================================================
# TOPIC IAM
# =============================================================================

# -----------------------------------------------------------------------------
# Pub/Sub Topic IAM Members
#
# locals.tf transforms:
#
# topic_iam_bindings = {
#   publishers = {
#     topic = "events"
#     role  = "roles/pubsub.publisher"
#
#     members = [
#       "serviceAccount:app1@project.iam.gserviceaccount.com",
#       "serviceAccount:app2@project.iam.gserviceaccount.com"
#     ]
#   }
# }
#
# into individual topic / role / member records.
#
# google_pubsub_topic_iam_member is intentionally used rather than an
# authoritative IAM policy resource.
#
# This means the module manages only the requested memberships.
# -----------------------------------------------------------------------------

resource "google_pubsub_topic_iam_member" "this" {
  for_each = local.topic_iam_members

  project = var.project_id

  # ---------------------------------------------------------------------------
  # Resolve Logical Topic Key
  # ---------------------------------------------------------------------------

  topic = google_pubsub_topic.this[
    each.value.topic
  ].name


  # ---------------------------------------------------------------------------
  # IAM Assignment
  # ---------------------------------------------------------------------------

  role   = each.value.role
  member = each.value.member
}


# =============================================================================
# SUBSCRIPTION IAM
# =============================================================================

# -----------------------------------------------------------------------------
# Pub/Sub Subscription IAM Members
#
# locals.tf performs the same type of transformation for subscriptions.
#
# Example caller input:
#
# subscription_iam_bindings = {
#   application_subscribers = {
#     subscription = "application"
#     role         = "roles/pubsub.subscriber"
#
#     members = [
#       "serviceAccount:consumer@project.iam.gserviceaccount.com"
#     ]
#   }
# }
#
# The logical subscription key is resolved to the actual Pub/Sub subscription
# name before the IAM membership is created.
# -----------------------------------------------------------------------------

resource "google_pubsub_subscription_iam_member" "this" {
  for_each = local.subscription_iam_members

  project = var.project_id

  # ---------------------------------------------------------------------------
  # Resolve Logical Subscription Key
  # ---------------------------------------------------------------------------

  subscription = google_pubsub_subscription.this[
    each.value.subscription
  ].name


  # ---------------------------------------------------------------------------
  # IAM Assignment
  # ---------------------------------------------------------------------------

  role   = each.value.role
  member = each.value.member
}
