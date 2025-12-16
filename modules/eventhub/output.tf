output "id" {
  description = "Event Hubs Namespace resource ID."
  value       = azurerm_eventhub_namespace.eventhub.id
}

output "name" {
  description = "Event Hubs Namespace name."
  value       = azurerm_eventhub_namespace.eventhub.name
}

output "sku" {
  description = "SKU of the namespace."
  value       = azurerm_eventhub_namespace.eventhub.sku
}

output "capacity" {
  description = "Capacity (throughput units)."
  value       = azurerm_eventhub_namespace.eventhub.capacity
}

output "namespace_primary_connection_string" {
  description = "Primary connection string for the namespace SAS rule."
  value       = try(azurerm_eventhub_namespace_authorization_rule.ns_sas[0].primary_connection_string, null)
  sensitive   = true
}

output "namespace_secondary_connection_string" {
  description = "Secondary connection string for the namespace SAS rule."
  value       = try(azurerm_eventhub_namespace_authorization_rule.ns_sas[0].secondary_connection_string, null)
  sensitive   = true
}

output "namespace_primary_key" {
  description = "Primary key for the namespace SAS rule."
  value       = try(azurerm_eventhub_namespace_authorization_rule.ns_sas[0].primary_key, null)
  sensitive   = true
}

output "namespace_secondary_key" {
  description = "Secondary key for the namespace SAS rule."
  value       = try(azurerm_eventhub_namespace_authorization_rule.ns_sas[0].secondary_key, null)
  sensitive   = true
}