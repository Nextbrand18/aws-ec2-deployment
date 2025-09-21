# Prepare a flattened list of all interfaces to create as aws_network_interface resources.
# Each item will have a unique id: "<instance_key>-<if_key>"
locals {
  flat_interfaces = flatten([
    for inst_key, inst in var.instances : [
      for if_key, ifcfg in lookup(inst, "interfaces", {}) : {
        id           = "${inst_key}-${if_key}"
        instance_key = inst_key
        if_key       = if_key
        device_index = ifcfg.device_index
        subnet_index = lookup(ifcfg, "subnet_index", 0)
        private_ips  = lookup(ifcfg, "private_ips", [])
        cidr_block   = lookup(ifcfg, "cidr_block", "")
        sg_keys      = lookup(ifcfg, "sg_keys", [])
        source_dest_check = lookup(ifcfg, "source_dest_check", true)
      }
    ]
  ])
}

# Create network interfaces
resource "aws_network_interface" "nic" {
  for_each = { for item in local.flat_interfaces : item.id => item }

  subnet_id       = element(var.subnet_ids, each.value.subnet_index)
  private_ips     = each.value.private_ips
  # map security group keys to IDs using var.sg_map; skip empty entries
  security_groups = compact([ for k in each.value.sg_keys : lookup(var.sg_map, k, null) ])
  source_dest_check = each.value.source_dest_check
  tags = merge(var.common_tags, { Name = "${each.value.instance_key}-${each.value.if_key}" })
}

# Create EC2 instances (no public IPs)
resource "aws_instance" "this" {
  for_each = var.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type

  # Prefer explicit availability_zone if provided, else leave AWS to choose from subnet
  availability_zone = lookup(each.value, "availability_zone", null)

  subnet_id = element(var.subnet_ids, each.value.subnet_index)
  associate_public_ip_address = false

  # Attach any network interfaces created for this instance. dynamic block iterates over NICs that belong to this instance.
  dynamic "network_interface" {
    for_each = [
      for item in local.flat_interfaces : item
      if item.instance_key == each.key
    ]
    content {
      network_interface_id = aws_network_interface.nic[network_interface.value.id].id
      device_index         = network_interface.value.device_index
      delete_on_termination = true
    }
  }

  # If no manual interface provided, ensure at least security groups via vpc_security_group_ids for primary interface
  vpc_security_group_ids = compact([
    # if explicit interfaces are present, those ENIs already carry SGs; but we still set SG on primary to be safe:
    lookup(var.sg_map, lookup(each.value, "security_group_key", ""), null)
  ])

  key_name = lookup(var.keypair_map, lookup(each.value, "key_pair_key", ""), null)
  iam_instance_profile = lookup(var.iam_profile_map, lookup(each.value, "iam_role_key", ""), null)

  ebs_optimized = lookup(each.value, "ebs_optimized", false)
  monitoring = lookup(each.value, "monitoring", true)

  metadata_options {
    http_tokens = lookup(lookup(each.value, "metadata", {}), "http_tokens", "required")
    http_endpoint = lookup(lookup(each.value, "metadata", {}), "http_endpoint", "enabled")
    http_put_response_hop_limit = lookup(lookup(each.value, "metadata", {}), "http_put_response_hop_limit", 2)
  }

  # root block device dynamic (create only when provided)
  dynamic "root_block_device" {
    for_each = lookup(each.value, "root_block_device", []) == null ? [] : [lookup(each.value, "root_block_device", {})]
    content {
      volume_size = lookup(root_block_device.value, "volume_size", 60)
      volume_type = lookup(root_block_device.value, "type", "gp3")
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", true)
      encrypted = var.ebs_encrypted
      kms_key_id = lookup(var.kms_map, lookup(each.value, "kms_key_key", ""), null)
    }
  }

  # additional EBS volumes
  dynamic "ebs_block_device" {
    for_each = lookup(each.value, "ebs_block_device", [])
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = ebs_block_device.value.volume_size
      volume_type = lookup(ebs_block_device.value, "type", "gp3")
      encrypted   = var.ebs_encrypted
      kms_key_id  = lookup(var.kms_map, lookup(each.value, "kms_key_key", ""), null)
    }
  }

  user_data = templatefile("${path.module}/userdata.ps1.tpl", {
    instance_name = lookup(each.value, "name", each.key),
    ssm_parameter  = var.cw_ssm_parameter
  })

  tags = merge({ Name = lookup(each.value, "name", each.key) }, var.common_tags, lookup(each.value, "tags", {}))
}


