# Create SNS topics
resource "aws_sns_topic" "this" {
  for_each = var.topics
  name     = each.value.name
  tags     = var.tags
}

# Build flattened list of topic+email items, then create one resource per subscription
locals {
  flat_subs = flatten([
    for t_key, t in var.topics : [
      for email in lookup(t, "email_subscriptions", []) : {
        id        = "${t_key}-${replace(email, "@", "_")}"
        topic_key = t_key
        email     = email
      }
    ]
  ])
}

resource "aws_sns_topic_subscription" "email_subs" {
  for_each = { for item in local.flat_subs : item.id => item }

  topic_arn = aws_sns_topic.this[each.value.topic_key].arn
  protocol  = "email"
  endpoint  = each.value.email
}
