##########################################
# SNS Module Variables
##########################################

variable "topics" {
  description = <<EOT
Map of SNS topics to create.
Each topic can include optional email subscriptions.

Example:
topics = {
  alerts = {
    name                = "alerts-topic"
    email_subscriptions = ["admin@example.com", "ops@example.com"]
  }
  audit = {
    name                = "audit-topic"
    email_subscriptions = ["security@example.com"]
  }
}
EOT
  type = map(object({
    name                = string
    email_subscriptions = optional(list(string), [])
  }))
  default     = {}
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}

#variable "topics" { type = map(object({ name = string, email_subscriptions = optional(list(string), []) })) }

