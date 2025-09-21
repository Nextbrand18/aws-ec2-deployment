variable "instances" {
  description = "Map of instance definitions"
  type        = map(any)
  default     = {}
}

variable "subnet_ids" {
  description = "List of subnet ids (ordered); instances reference subnets by index"
  type        = list(string)
  default     = []
}

variable "sg_map" {
  description = "Map of security group key => sg id"
  type        = map(string)
  default     = {}
}

variable "keypair_map" {
  description = "Map of key pair key => key name"
  type        = map(string)
  default     = {}
}

variable "iam_profile_map" {
  description = "Map of iam role key => instance profile name"
  type        = map(string)
  default     = {}
}

variable "kms_map" {
  description = "Map of kms key key => arn"
  type        = map(string)
  default     = {}
}

variable "cw_ssm_parameter" {
  description = "SSM parameter name where CloudWatch agent config is stored"
  type        = string
  default     = "/cloudwatch/agent/config/cloudwatch-agent-config"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "ebs_encrypted" {
  description = "Whether EBS volumes should be encrypted"
  type        = bool
  default     = true
}
