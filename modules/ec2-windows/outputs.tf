# Output map used by cloudwatch and backups: instance_key => { id, name }
output "instance_map" {
  value = { for k, i in aws_instance.this : k => { id = i.id, name = lookup(var.instances[k], "name", k) } }
}

output "instance_ids" {
  value = { for k, i in aws_instance.this : k => i.id }
}

output "private_ips" {
  value = { for k, i in aws_instance.this : k => i.private_ip }
}