output "vault_names" { value = { for k, v in aws_backup_vault.vault : k => v.name } }
output "plan_ids"   { value = { for k, v in aws_backup_plan.plan : k => v.id } }
output "role_arns"  { value = { for k, v in aws_iam_role.backup_role : k => v.arn } }
