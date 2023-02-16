packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "vpc_id" {
  type    = string
  default = "vpc-80664de5"
}

variable "subnet_id" {
  type    = string
  default = "subnet-a98f92cc"
}

variable "cidr_whitelisting" {
  type    = list(string)
  default = ["127.0.0.1/32"]
}

variable "windows_server_version" {
  type    = string
  default = "2019"
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "volume_size" {
  type    = string
  default = "50"
}

variable "tags" {
  type = map(string)
  default = {
    environment = "nonprod"
    type        = "packer"
  }
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "windows_packer" {
  ami_name              = "w${var.windows_server_version}-packer-${local.timestamp}"
  communicator          = "winrm"
  force_deregister      = true
  force_delete_snapshot = true
  instance_type         = "${var.instance_type}"
  region                = "${var.aws_region}"
  source_ami_filter {
    filters = {
      architecture = "x86_64"
      name                = "Windows_Server-${var.windows_server_version}-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    # the "Amazon" ami owner
    owners = ["801119661308"]
  }
  temporary_iam_instance_profile_policy_document {
    Version = "2012-10-17"
    Statement {
      Effect = "Allow"
      Action = [
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CopyImage",
        "ec2:CreateImage",
        "ec2:CreateKeypair",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteKeypair",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSnapshot",
        "ec2:DeleteVolume",
        "ec2:DeregisterImage",
        "ec2:DescribeImageAttribute",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSnapshots",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "ec2:GetPasswordData",
        "ec2:ModifyImageAttribute",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifySnapshotAttribute",
        "ec2:RegisterImage",
        "ec2:RunInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ]
      Resource = ["*"]
    }
  }
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_type           = "gp2"
    volume_size           = "${var.volume_size}"
    delete_on_termination = true
  }
  subnet_id                             = "${var.subnet_id}"
  user_data_file                        = "./scripts/bootstrap_win.txt"
  vpc_id                                = "${var.vpc_id}"
  winrm_insecure                        = true
  winrm_use_ssl                         = true
  winrm_port                            = 5986
  winrm_timeout                         = "20m"
  winrm_username                        = "Administrator"
  associate_public_ip_address           = true
  temporary_security_group_source_cidrs = var.cidr_whitelisting
  run_tags                              = "${var.tags}"
  run_volume_tags                       = "${var.tags}"
}

build {
  sources = ["source.amazon-ebs.windows_packer"]
  provisioner "powershell" {
    scripts = ["${path.root}/scripts/install_chocolatey.ps1", "${path.root}/scripts/install_packages.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "35m"
  }

  provisioner "powershell" {
    inline = [
      #Sysprep the instance with ECLaunch v2. Reset enables runonce scripts again.
      "Set-Location $env:programfiles/amazon/ec2launch",
      "./ec2launch.exe reset -c -b",
      "./ec2launch.exe sysprep -c -b"
    ]
  }
}
