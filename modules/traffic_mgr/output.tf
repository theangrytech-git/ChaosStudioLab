output "profile_id" {
  value = azurerm_traffic_manager_profile.tm_profile.id
}

output "fqdn" {
  value = azurerm_traffic_manager_profile.tm_profile.fqdn
}

output "endpoint_names" {
  value = concat(
    var.create_public_ip ? [azurerm_traffic_manager_azure_endpoint.pip_ep[0].name] : [],
    try(keys(azurerm_traffic_manager_azure_endpoint.pip_ep), [])
  )
}

output "endpoint_ids" {
  value = concat(
    var.create_public_ip ? [azurerm_traffic_manager_azure_endpoint.pip_ep[0].id] : [],
    try(values(azurerm_traffic_manager_azure_endpoint.pip_ep)[*].id, [])
  )
}

output "public_ip_id" {
  value       = var.create_public_ip ? azurerm_public_ip.pip[0].id : null
  description = "ID of the managed Public IP (if created)."
}

output "public_ip_address" {
  value       = var.create_public_ip ? azurerm_public_ip.pip[0].ip_address : null
  description = "IP address of the managed Public IP (if created)."
}