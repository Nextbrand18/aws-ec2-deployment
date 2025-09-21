variable "keys" {
  description = "Map of key definitions: key => { key_name = string }"
  type        = map(object({ key_name = string }))
  default     = {}
}

variable "tags" {
  description = "Tags applied to created key pair & secret"
  type        = map(string)
  default     = {}
}
