provider "aws" {
  region = var.region
  # access_key = var.AccessKeyID
  # secret_key = var.SecretAccessKey
}

data "aws_vpc" "site" {
  filter {
    name   = "tag:ves.io/site_name"
    values = [var.aws_site.value.name]
  }
}

data "aws_subnet" "workload" {
  filter {
    name   = "tag:ves.io/subnet-type"
    values = ["workload"]
  }
  filter {
    name   = "tag:ves.io/site_name"
    values = [var.aws_site.value.name]
  }
}

data "aws_subnet" "sli" {
  filter {
    name   = "tag:ves.io/subnet-type"
    values = ["site-local-inside"]
  }
  filter {
    name   = "tag:ves.io/site_name"
    values = [var.aws_site.value.name]
  }
}

#
# Create a random id
#
resource "random_id" "id" {
  byte_length = 2
}

#
# Create random password for BIG-IP
#
resource "random_string" "password" {
  length      = 16
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

#
# Create Secret Store and Store BIG-IP Password
#
resource "aws_secretsmanager_secret" "bigip" {
  name = format("%s-bigip-secret-%s", var.prefix, random_id.id.hex)
}
resource "aws_secretsmanager_secret_version" "bigip-pwd" {
  secret_id     = aws_secretsmanager_secret.bigip.id
  secret_string = random_string.password.result
}

#
# Create a security group for BIG-IP
#
module "external-network-security-group-public" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP "
  vpc_id      = data.aws_vpc.site.id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

#
# Create a security group for BIG-IP Management
#
module "mgmt-network-security-group" {
  source = "terraform-aws-modules/security-group/aws"
  # insert the 2 required variables here

  name        = format("%s-mgmt-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP Management"
  vpc_id      = data.aws_vpc.site.id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["https-443-tcp", "https-8443-tcp", "ssh-tcp"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
  //ecdsa_curve = "P384"
}

resource "aws_key_pair" "generated_key" {
  key_name   = format("%s-%s-%s", var.prefix, var.ec2_key_name, random_id.id.hex)
  public_key = tls_private_key.example.public_key_openssh
}

#
# Create BIG-IP
#
module "bigip" {
  source                      = "github.com/f5devcentral/terraform-aws-bigip-module"
  count                       = var.instance_count
  prefix                      = format("%s-2nic", var.prefix)
  ec2_key_name                = aws_key_pair.generated_key.key_name
  aws_secretmanager_secret_id = aws_secretsmanager_secret.bigip.id
  mgmt_subnet_ids             = [{ "subnet_id" = data.aws_subnet.sli.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids      = [module.mgmt-network-security-group.security_group_id]
  external_securitygroup_ids  = [module.external-network-security-group-public.security_group_id]
  external_subnet_ids         = [{ "subnet_id" = data.aws_subnet.workload.id, "public_ip" = false, "private_ip_primary" = "", "private_ip_secondary" = "" }]
}

resource "null_resource" "clusterDO" {
  count = var.instance_count
  provisioner "local-exec" {
    command = "cat > DO_2nic-instance${count.index}.json <<EOL\n ${module.bigip[count.index].onboard_do}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf DO_2nic-instance${count.index}.json"
  }
  depends_on = [module.bigip.onboard_do]
}

#
# Variables used by this example
#
locals {
  allowed_mgmt_cidr = "0.0.0.0/0"
  allowed_app_cidr  = "0.0.0.0/0"
}

