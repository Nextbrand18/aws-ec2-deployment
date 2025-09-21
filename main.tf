# Networking: find existing VPC & subnets, create VPC endpoints for SSM, logs, monitoring, secretsmanager
module "networking" {
  source             = "./modules/networking"
  vpc_name           = var.vpc_name
  subnet_environment = var.subnet_environment
  region             = var.region
  tags               = var.common_tags
}

# KMS keys
module "kms" {
  source = "./modules/kms"
  keys   = var.kms_keys
  tags   = var.common_tags
}

# Key pair generation (tls -> aws_key_pair -> secret)
module "key_pairs" {
  source = "./modules/key-pair"
  keys   = var.key_pairs
  tags   = var.common_tags
}

# IAM roles
module "iam" {
  source = "./modules/iam"
  roles  = var.iam_roles
  tags   = var.common_tags
}

# Security groups
module "security_groups" {
  source      = "./modules/security-groups"
  vpc_id      = module.networking.vpc_id
  groups      = var.security_groups
  common_tags = var.common_tags
}

# SNS topics
module "sns" {
  source = "./modules/sns"
  topics = var.sns_topics
  tags   = var.common_tags
}

# Secrets placeholders
module "secrets" {
  source  = "./modules/secrets-manager"
  secrets = var.secrets
  tags    = var.common_tags
}

# Backup plans
module "backup" {
  source  = "./modules/backup"
  backups = var.backup_plans
  tags    = var.common_tags
}

# CloudWatch: create SSM parameter (agent config), log group, and alarms (combined)
module "cloudwatch" {
  source        = "./modules/cloudwatch"
  name          = "cloudwatch-agent-config"
  cw_agent_config_json = null
  alarm_group   = var.alarm_group
  instances     = { for k, v in var.instances : k => { id = "", name = v.name, attach = lookup(v, "attach_alarms", false) } }
  sns_topic_arn = var.alarm_sns_topic_key != "" ? lookup(module.sns.topic_arns, var.alarm_sns_topic_key, "") : ""
  tags          = var.common_tags
}

# EC2 Windows instances (pass resolved maps/ids)
module "ec2" {
  source           = "./modules/ec2-windows"
  instances        = var.instances
  subnet_ids       = module.networking.subnet_ids
  sg_map           = module.security_groups.sg_ids
  keypair_map      = module.key_pairs.key_names
  iam_profile_map  = module.iam.instance_profile_names
  kms_map          = module.kms.key_arns
  cw_ssm_parameter = module.cloudwatch.ssm_parameter_name
  common_tags      = var.common_tags
}

# CloudWatch alarms module uses ec2 outputs (we created combined cloudwatch already,
# but cloudwatch module expects instance ids, so after EC2 apply you can provide real IDs.
# The root cloudwatch module above used placeholder instances; we will create actual alarms
# in a separate run by passing module.ec2.instance_map into another call if desired.
# To keep things linear, we also run a second cloudwatch_alarms module fed with real instance_map:
module "cloudwatch_alarms" {
  source        = "./modules/cloudwatch"
  name          = "cloudwatch-agent-config-alarms"
  cw_agent_config_json = null
  alarm_group   = var.alarm_group
  instances     = module.ec2.instance_map
  sns_topic_arn = var.alarm_sns_topic_key != "" ? lookup(module.sns.topic_arns, var.alarm_sns_topic_key, "") : ""
  tags          = var.common_tags
  # note: this duplicates the SSM parameter creation but is safe - SSM param name is the same
  # and Terraform will manage it. If you prefer one module instance, call it after EC2 and pass instances.
}

# Backup selections: register created instances to backup plans if backup_key present
data "aws_caller_identity" "current" {}

resource "aws_backup_selection" "per_instance" {
  for_each = {
    for inst_key, inst in var.instances :
    inst_key => inst if lookup(inst, "backup_key", "") != "" && contains(keys(module.backup.plan_ids), lookup(inst, "backup_key", ""))
  }

  name = "${each.key}-backup-selection"

  iam_role_arn = lookup(module.backup.role_arns, lookup(each.value, "backup_key", ""), "")
  plan_id      = lookup(module.backup.plan_ids, lookup(each.value, "backup_key", ""), "")

  resources = [
    format("arn:aws:ec2:%s:%s:instance/%s", var.region, data.aws_caller_identity.current.account_id, module.ec2.instance_map[each.key].id)
  ]

  lifecycle {
    ignore_changes = [resources]
  }
}
