output "vnet_id" {
  value = azurerm_virtual_network.vnet_uks.id
}

output "subnet_ids" {
  value = { for k, v in azurerm_subnet.subnets : k => v.id }
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet_uks.name
}

output "subnet_prefixes" {
  value = { for s in azurerm_subnet.subnets : s.name => s.address_prefixes }
}