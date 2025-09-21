output "ec2_instance_map" {
  value = module.ec2.instance_map
}

output "keypair_secret_arns" {
  value = module.key_pairs.private_key_secret_arns
}

output "kms_key_arns" {
  value = module.kms.key_arns
}

output "sns_topic_arns" {
  value = module.sns.topic_arns
}
