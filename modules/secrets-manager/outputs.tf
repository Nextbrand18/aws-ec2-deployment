output "secret_arns" {
  value = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

