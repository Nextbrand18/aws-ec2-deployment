output "ssm_parameter_name" {
  value = aws_ssm_parameter.cw_agent_config.name
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.windows.name
}