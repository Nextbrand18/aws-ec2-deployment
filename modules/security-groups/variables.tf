variable "vpc_id" {
  type = string
}

variable "groups" {
  description = "Map of security group definitions"
  type        = map(any)
  default     = {}
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
