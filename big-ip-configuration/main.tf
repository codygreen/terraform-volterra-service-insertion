terraform {
  required_providers {
    bigip = {
      source                = "terraform-providers/bigip"
      configuration_aliases = [bigip.bigip1, bigip.bigip2]
    }
  }
  required_version = ">= 0.13"
}

provider "bigip" {
  alias    = "bigip1"
  address  = var.mgmtPublicIP.value[0][0]
  username = var.f5_username.value[0]
  password = var.bigip_password.value[0]
}

provider "bigip" {
  alias    = "bigip2"
  address  = var.mgmtPublicIP.value[1][0]
  username = var.f5_username.value[1]
  password = var.bigip_password.value[1]
}

# Apply DO declaration
resource "bigip_do" "bigip1" {
  provider = bigip.bigip1
  do_json  = file("DO_2nic-instance0.json")
  timeout  = 15
  # lifecycle {
  #   ignore_changes = [
  #     do_json
  #   ]
  # }
}

# Apply DO declaration
resource "bigip_do" "bigip2" {
  provider = bigip.bigip2
  do_json  = file("DO_2nic-instance1.json")
  timeout  = 15
  #   lifecycle {
  #     ignore_changes = [
  #       do_json
  #     ]
  #   }
}

# Example Usage for json file
resource "bigip_as3" "bigip1" {
  provider = bigip.bigip1
  as3_json = file("as3.json")
}
