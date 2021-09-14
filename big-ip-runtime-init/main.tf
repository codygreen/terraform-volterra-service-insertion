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
# Create a security group for BIG-IP
#
module "external-network-security-group-public" {
  source = "terraform-aws-modules/security-group/aws"

  name        = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  description = "Security group for BIG-IP "
  vpc_id      = data.aws_vpc.site.id

  ingress_cidr_blocks = var.AllowedIPs
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]

  # Allow BIG-IP to BIG-IP communication
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.external-network-security-group-public.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

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

  # Allow BIG-IP to BIG-IP communication
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = module.mgmt-network-security-group.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

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

## remove in production
resource "local_file" "key" {
  filename        = "${path.module}/rsa.key"
  content         = tls_private_key.example.private_key_pem
  file_permission = "0400"
}

#
# Create onboard script
#
data "template_file" "user_data" {
  template = file("${path.module}/onboard.tmpl")
  vars = {
    bigip_username = var.f5_username
    bigip_password = random_string.password.result
  }
}

#
# Create BIG-IP
#
module "bigip" {
  source                     = "github.com/f5devcentral/terraform-aws-bigip-module"
  count                      = var.instance_count
  prefix                     = format("%s-2nic", var.prefix)
  ec2_key_name               = aws_key_pair.generated_key.key_name
  f5_password                = random_string.password.result
  mgmt_subnet_ids            = [{ "subnet_id" = data.aws_subnet.sli.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [module.mgmt-network-security-group.security_group_id]
  external_securitygroup_ids = [module.external-network-security-group-public.security_group_id]
  external_subnet_ids        = [{ "subnet_id" = data.aws_subnet.workload.id, "public_ip" = false, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  custom_user_data           = data.template_file.user_data.rendered
}
