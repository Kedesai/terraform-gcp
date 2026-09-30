# -----------------------------------------------------------------------------
# Pub/Sub Topic Outputs
#
# Outputs are keyed by the logical topic keys supplied through var.topics.
# -----------------------------------------------------------------------------

output "topic_ids" {
  description = "Map of Pub/Sub topic resource IDs."

  value = {
    for key, topic in google_pubsub_topic.this :
    key => topic.id
  }
}

output "topic_names" {
  description = "Map of Pub/Sub topic names."

  value = {
    for key, topic in google_pubsub_topic.this :
    key => topic.name
  }
}


# -----------------------------------------------------------------------------
# Pub/Sub Subscription Outputs
#
# Outputs are keyed by the logical subscription keys supplied through
# var.subscriptions.
# -----------------------------------------------------------------------------

output "subscription_ids" {
  description = "Map of Pub/Sub subscription resource IDs."

  value = {
    for key, subscription in google_pubsub_subscription.this :
    key => subscription.id
  }
}

output "subscription_names" {
  description = "Map of Pub/Sub subscription names."

  value = {
    for key, subscription in google_pubsub_subscription.this :
    key => subscription.name
  }
}

output "subscription_topics" {
  description = "Map of topic resource IDs associated with subscriptions."

  value = {
    for key, subscription in google_pubsub_subscription.this :
    key => subscription.topic
  }
}


# -----------------------------------------------------------------------------
# IAM Outputs
#
# These outputs show only IAM memberships managed by this module.
# -----------------------------------------------------------------------------

output "topic_iam_members" {
  description = "Topic-level IAM memberships managed by this module."

  value = {
    for key, assignment in google_pubsub_topic_iam_member.this :
    key => {
      topic  = assignment.topic
      role   = assignment.role
      member = assignment.member
    }
  }
}

output "subscription_iam_members" {
  description = "Subscription-level IAM memberships managed by this module."

  value = {
    for key, assignment in google_pubsub_subscription_iam_member.this :
    key => {
      subscription = assignment.subscription
      role         = assignment.role
      member       = assignment.member
    }
  }
}
