variable "roles" {
  description = "Map of IAM roles: key => { role_name = optional, policies = list(arns) }"
  type        = map(object({ role_name = optional(string), policies = list(string) }))
  default     = {}
}

variable "tags" {
  description = "Common tags applied to roles & instance profiles"
  type        = map(string)
  default     = {}
}
