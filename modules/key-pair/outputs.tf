output "key_names" {
  value = { for k, v in aws_key_pair.kp : k => v.key_name }
}

output "private_key_secret_arns" {
  value = { for k, v in aws_secretsmanager_secret.kp_secret : k => v.arn }
}
