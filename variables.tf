variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "vpc_name" {
  description = "Tag:Name of existing VPC to use"
  type        = string
}

variable "subnet_environment" {
  description = "Value of tag:Environment on subnets to select (eg. prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to many resources"
  type        = map(string)
  default     = {}
}

variable "kms_keys" {
  description = "Map of KMS keys to create: key => { description = string }"
  type        = map(any)
  default     = {}
}

variable "key_pairs" {
  description = "Map of keypairs to generate: key => { key_name = string }"
  type        = map(any)
  default     = {}
}

variable "iam_roles" {
  description = "Map of IAM roles: key => { role_name = optional, policies = list(arns) }"
  type        = map(any)
  default     = {}
}

variable "security_groups" {
  description = "Map of security groups and rules"
  type        = map(any)
  default     = {}
}

variable "sns_topics" {
  description = "Map of SNS topics and subscription lists"
  type        = map(any)
  default     = {}
}

variable "backup_plans" {
  description = "Map of backup plans: key => { name = string, schedule = string }"
  type        = map(any)
  default     = {}
}

variable "secrets" {
  description = "Placeholders for Secrets Manager secrets (do not put secret values here)"
  type        = map(any)
  default     = {}
}

variable "instances" {
  description = <<EOT
Map of instances to provision. Each instance (map value) should include:
- name, ami, instance_type, subnet_index
- security_group_key, iam_role_key, key_pair_key
Optional: kms_key_key, backup_key, root_block_device, ebs_block_device,
          monitoring, attach_alarms, ebs_optimized, availability_zone,
          metadata, interfaces (map keyed by eth0/eth1...), tags
EOT
  type = map(object({
    name               = string
    ami                = string
    instance_type      = string
    subnet_index       = number
    security_group_key = string
    iam_role_key       = string
    key_pair_key       = string
    kms_key_key        = optional(string, "")
    backup_key         = optional(string, "")
    root_block_device  = optional(object({ volume_size = number, type = string, delete_on_termination = bool }), null)
    ebs_block_device   = optional(list(object({ device_name = string, volume_size = number, type = string })), [])
    monitoring         = optional(bool, true)
    attach_alarms      = optional(bool, false)
    ebs_optimized      = optional(bool, false)
    availability_zone  = optional(string, "")
    metadata           = optional(object({
      http_endpoint               = optional(string, "enabled")
      http_tokens                 = optional(string, "required")
      http_put_response_hop_limit = optional(number, 2)
    }), null)
    interfaces = optional(map(object({
      device_index      = number
      subnet_index      = optional(number, 0)
      private_ips       = optional(list(string), [])
      cidr_block        = optional(string, "")
      sg_keys           = optional(list(string), [])
      source_dest_check = optional(bool, true)
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "alarm_group" {
  description = "Single list (group) of alarm definitions applied to instances with attach_alarms = true"
  type = list(object({
    name                = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
  }))
  default = []
}

variable "alarm_sns_topic_key" {
  description = "Key in sns_topics map to use for alarm SNS notifications (empty = none)"
  type        = string
  default     = ""
}
