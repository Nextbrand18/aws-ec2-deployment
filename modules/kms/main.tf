resource "aws_kms_key" "this" {
  for_each = var.keys
  description = lookup(each.value, "description", "tf-managed-kms")
  deletion_window_in_days = 30
  enable_key_rotation = true
  tags = var.tags
}

resource "aws_kms_alias" "alias" {
  for_each = var.keys
  name = "alias/${each.key}"
  target_key_id = aws_kms_key.this[each.key].key_id
}
