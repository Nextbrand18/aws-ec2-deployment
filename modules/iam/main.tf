resource "aws_iam_role" "this" {
  for_each = var.roles

  name = lookup(each.value, "role_name", "${each.key}-role")
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = var.tags
}

resource "aws_iam_instance_profile" "profile" {
  for_each = var.roles
  name = "${aws_iam_role.this[each.key].name}-profile"
  role = aws_iam_role.this[each.key].name
  tags = var.tags
}

# Flatten role x policy into a list of objects then attach
locals {
  role_policy_pairs = flatten([
    for r_key, r in var.roles : [
      for p in r.policies : {
        id = "${r_key}::${replace(p, ":", "_")}"
        role_key = r_key
        policy_arn = p
      }
    ]
  ])
}

resource "aws_iam_role_policy_attachment" "attach" {
  for_each = { for pair in local.role_policy_pairs : pair.id => pair }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}
