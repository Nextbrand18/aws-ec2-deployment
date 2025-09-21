variable "keys" {
  description = "Map of KMS keys to create: key => { description = optional }"
  type        = map(object({ description = optional(string, "") }))
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
