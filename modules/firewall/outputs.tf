output "firewall_id" {
  description = "ARM id of the Azure Firewall"
  value       = azurerm_firewall.firewall.id
}

output "firewall_name" {
  description = "Name of the Azure Firewall"
  value       = azurerm_firewall.firewall.name
}

output "public_ip_id" {
  description = "ARM id of the primary dataplane Public IP (null if not set)"
  value       = try(azurerm_public_ip.firewall_pip[0].id, var.public_ip_id)
}

output "public_ip_address" {
  description = "IPv4 address of the primary dataplane Public IP (null if not created)"
  value       = try(azurerm_public_ip.firewall_pip[0].ip_address, null)
}

output "management_public_ip_id" {
  description = "ARM id of the management Public IP (null if not set)"
  value       = try(azurerm_public_ip.firewall_mgmt_pip[0].id, var.management_public_ip_id)
}

output "management_public_ip_address" {
  description = "IPv4 address of the management Public IP (null if not created)"
  value       = try(azurerm_public_ip.firewall_mgmt_pip[0].ip_address, null)
}

output "private_ip_address" {
  description = "Firewall private IP (from the first ip_configuration)"
  value       = try(azurerm_firewall.firewall.ip_configuration[0].private_ip_address, null)
}