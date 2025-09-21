variable "secrets" {
  description = "Map of secret placeholders: key => { name = string, value = string }"
  type = map(object({
    name  = string
    value = string
    description = optional(string, "")
  }))
}

variable "tags" {
  type = map(string)
  default = {}
}


