output "private_endpoint_ids" {
  description = "IDs of the created private endpoints"
  value       = [for pe in azurerm_private_endpoint.private_endpoint : pe.id]
}

output "private_endpoint_ip_addresses" {
  description = "Private IP addresses of the private endpoints"
  value       = [for pe in azurerm_private_endpoint.private_endpoint : pe.private_service_connection[0].private_ip_address]
}
