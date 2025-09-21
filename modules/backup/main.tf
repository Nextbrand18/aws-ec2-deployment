resource "aws_backup_vault" "vault" {
  for_each = var.backups
  name = each.value.name
  tags = var.tags
}

resource "aws_backup_plan" "plan" {
  for_each = var.backups
  name = "${each.value.name}-plan"
  rule {
    rule_name = "${each.key}-rule"
    target_vault_name = aws_backup_vault.vault[each.key].name
    schedule = each.value.schedule
    lifecycle { delete_after = 90 }
  }
}

resource "aws_iam_role" "backup_role" {
  for_each = var.backups
  name = "${each.value.name}-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "backup.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "backup_policy" {
  for_each = var.backups
  name = "${each.value.name}-backup-policy"
  role = aws_iam_role.backup_role[each.key].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = ["ec2:CreateSnapshot","ec2:DescribeVolumes","ec2:DescribeInstances"], Resource = "*" }]
  })
}
