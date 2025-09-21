# output "subscription_ids" {
#   value = [for s in aws_sns_topic_subscription.email_subs : s.id]
# }

output "topic_arns" {
  value = { for k, v in aws_sns_topic.this : k => v.arn }
}
