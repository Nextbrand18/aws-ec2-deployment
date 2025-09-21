resource "aws_security_group" "this" {
  for_each = var.groups

  name        = lookup(each.value, "name", each.key)
  description = lookup(each.value, "description", "managed-sg")
  vpc_id      = var.vpc_id
  tags        = merge(var.common_tags, lookup(each.value, "tags", {}))

  dynamic "ingress" {
    for_each = lookup(each.value, "ingress", [])
    content {
      description = lookup(ingress.value, "description", null)
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", [])
    }
  }

  dynamic "egress" {
    for_each = lookup(each.value, "egress", [])
    content {
      description = lookup(egress.value, "description", null)
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = lookup(egress.value, "cidr_blocks", [])
    }
  }
}
