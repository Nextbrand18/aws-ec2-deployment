# Select VPC by tag:Name
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Select subnets by tag:Environment within VPC
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name   = "tag:Environment"
    values = [var.subnet_environment]
  }
}

# Create up to two interface endpoints to allow SSM/CloudWatch/SecretsManager from private subnets
locals {
  services = ["ssm", "ssmmessages", "ec2messages", "logs", "monitoring", "secretsmanager"]
  endpoint_subnets = slice(data.aws_subnets.selected.ids, 0, min([length(data.aws_subnets.selected.ids), 2]))
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.services)

  vpc_id            = data.aws_vpc.selected.id
  service_name      = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.endpoint_subnets
  private_dns_enabled = true
  tags = var.tags
}
