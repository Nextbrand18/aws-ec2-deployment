# Provide a safe default JSON if none passed in
locals {
  config_json = var.cw_agent_config_json != "" ? var.cw_agent_config_json : <<-JSON
  {
    "agent": { "metrics_collection_interval": 60 },
    "metrics": {
      "append_dimensions": { "InstanceId": "$${aws:InstanceId}" },
      "metrics_collected": {
        "LogicalDisk": { "measurement": [ "% Free Space" ], "metrics_collection_interval": 60, "resources": [ "*" ] },
        "Memory": { "measurement": [ "% Committed Bytes In Use" ], "metrics_collection_interval": 60 }
      }
    }
  }
  JSON
}

# Store CloudWatch agent config in SSM so instances can fetch at boot
resource "aws_ssm_parameter" "cw_agent_config" {
  name  = "/cloudwatch/agent/config/${var.name}"
  type  = "String"
  value = local.config_json
  tags  = var.tags
}

# Log group used by agent
resource "aws_cloudwatch_log_group" "windows" {
  name = "/cloudwatch/windows/${var.name}"
  retention_in_days = 14
  tags = var.tags
}

# Flatten alarms for instances that opted in (one alarm per resource)
locals {
  instance_alarm_list = flatten([
    for inst_key, inst in var.instances : (
      inst.attach ? [
        for alarm in var.alarm_group : {
          id          = "${inst_key}-${alarm.name}"
          instance_key = inst_key
          instance_id  = inst.id
          alarm        = alarm
        }
      ] : []
    )
  ])
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = { for item in local.instance_alarm_list : item.id => item }

  alarm_name          = each.key
  comparison_operator = each.value.alarm.comparison_operator
  evaluation_periods  = each.value.alarm.evaluation_periods
  metric_name         = each.value.alarm.metric_name
  namespace           = each.value.alarm.namespace
  period              = each.value.alarm.period
  statistic           = each.value.alarm.statistic
  threshold           = each.value.alarm.threshold

  dimensions = {
    InstanceId = each.value.instance_id
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  tags = var.tags
}


