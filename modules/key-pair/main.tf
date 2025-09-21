# Generate TLS private key per entry
resource "tls_private_key" "kp" {
  for_each = var.keys
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "kp" {
  for_each  = var.keys
  key_name  = each.value.key_name
  public_key = tls_private_key.kp[each.key].public_key_openssh
  tags = var.tags
}

# Store private key in Secrets Manager
resource "aws_secretsmanager_secret" "kp_secret" {
  for_each = var.keys
  name     = "${each.value.key_name}-private"
  tags     = var.tags
}

resource "aws_secretsmanager_secret_version" "kp_secret_version" {
  for_each      = var.keys
  secret_id     = aws_secretsmanager_secret.kp_secret[each.key].id
  secret_string = tls_private_key.kp[each.key].private_key_pem
}
