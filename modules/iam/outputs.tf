output "role_names" {
  value = { for k, r in aws_iam_role.this : k => r.name }
}

output "instance_profile_names" {
  value = { for k, p in aws_iam_instance_profile.profile : k => p.name }
}
