variable "name" { 
  type = string 
  
  }

variable "cw_agent_config_json" { 
  type = string 
  default = "" 
}

variable "alarm_group" {
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

variable "instances" {
  type = map(object({ id = string, name = string, attach = bool }))
  default = {}
}

variable "sns_topic_arn" { 
  type = string 
  default = "" 
}

variable "tags" { 
  type = map(string) 
  default = {} 
}
