source "amazon-ebs" "builder" {
  ami_name                  = "${var.ami_name_prefix}-${var.version}"
  ami_users                 = var.ami_account_ids
  communicator              = "ssh"
  force_delete_snapshot     = var.force_delete_snapshot
  force_deregister          = var.force_deregister
  imds_support              = "v2.0"
  instance_type             = var.aws_instance_type
  region                    = var.aws_region
  ssh_clear_authorized_keys = var.ssh_clear_authorized_keys
  ssh_private_key_file      = var.ssh_private_key_file
  ssh_username              = var.ssh_username
  ssh_keypair_name          = "packer-builders-${var.aws_region}"
  iam_instance_profile      = "packer-builders-${var.aws_region}"

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    encrypted             = true
    iops                  = var.root_volume_iops
    kms_key_id            = var.kms_key_id
    throughput            = var.root_volume_throughput
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
  }

  dynamic "launch_block_device_mappings" {
    for_each = var.swap_volume_size_gb > 0 ? [1] : []

    content {
      delete_on_termination = true
      device_name           = var.swap_volume_device_node
      encrypted             = true
      iops                  = var.swap_volume_iops
      kms_key_id            = var.kms_key_id
      throughput            = var.swap_volume_throughput
      volume_size           = var.swap_volume_size_gb
      volume_type           = "gp3"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  security_group_filter {
    filters = {
      "group-name": "packer-builders-${var.aws_region}"
    }
  }

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name =  "${var.aws_source_ami_filter_name}"
      root-device-type = "ebs"
    }
    owners = ["${var.aws_source_ami_owner_id}"]
    most_recent = true
  }

  subnet_filter {
    filters = {
          "tag:Name": "${var.aws_subnet_filter_name}"
    }
    most_free = true
    random = false
  }

  run_tags = {
    AMI     = "${var.ami_name_prefix}"
    Name    = "packer-builder-${var.ami_name_prefix}-${var.version}"
    Service = "packer-builder"
  }

  run_volume_tags = {
    Builder = "packer-{{packer_version}}"
    Name    = "${var.ami_name_prefix}-${var.version}"
  }

  tags = {
    Builder = "packer-{{packer_version}}"
    Name    = "${var.ami_name_prefix}-${var.version}"
  }
}
