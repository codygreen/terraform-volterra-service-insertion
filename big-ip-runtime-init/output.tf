# BIG-IP Management Public IP Addresses
output "mgmtPublicIP" {
  value = [
    module.bigip1.*.mgmtPublicIP,
    module.bigip2.*.mgmtPublicIP
  ]
}

# BIG-IP Management Public DNS Address
output "mgmtPublicDNS" {
  value = [
    module.bigip1.*.mgmtPublicDNS,
    module.bigip2.*.mgmtPublicDNS
  ]
}

# BIG-IP Management Port
output "mgmtPort" {
  value = [
    module.bigip1.*.mgmtPort,
    module.bigip2.*.mgmtPort
  ]
}

# BIG-IP Username
output "f5_username" {
  value = [
    module.bigip1.*.f5_username,
    module.bigip2.*.f5_username
  ]
}

# BIG-IP Password
output "bigip_password" {
  value = [
    module.bigip1.*.bigip_password,
    module.bigip2.*.bigip_password
  ]
}

output "mgmtPublicURL" {
  description = "mgmtPublicURL"
  value = [
    length(flatten(module.bigip1.*.mgmtPublicDNS)) > 0 ? [for i in range(var.instance_count) : format("https://%s:%s", module.bigip1[i].mgmtPublicDNS[0], module.bigip1[i].mgmtPort)] : tolist([]),
    length(flatten(module.bigip2.*.mgmtPublicDNS)) > 0 ? [for i in range(var.instance_count) : format("https://%s:%s", module.bigip2[i].mgmtPublicDNS[0], module.bigip2[i].mgmtPort)] : tolist([])
  ]
}

output "private_addresses" {
  description = "List of BIG-IP private addresses"
  value = [
    module.bigip1.*.private_addresses,
    module.bigip2.*.private_addresses
  ]
}

output "public_addresses" {
  description = "List of BIG-IP public addresses"
  value = [
    module.bigip1.*.public_addresses,
    module.bigip2.*.public_addresses
  ]
}

output "test" {
  value = module.bigip1.0.private_addresses.mgmt_private.private_ip[0]
}
