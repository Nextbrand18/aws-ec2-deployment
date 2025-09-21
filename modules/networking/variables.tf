variable "vpc_name" {
  description = "VPC tag:Name to search"
  type        = string
}

variable "subnet_environment" {
  description = "Subnet tag:Environment value to filter subnets"
  type        = string
}

variable "region" {
  description = "Region used to build endpoint service names"
  type        = string
}

variable "tags" {
  description = "Tags applied to created endpoints"
  type        = map(string)
  default     = {}
}
