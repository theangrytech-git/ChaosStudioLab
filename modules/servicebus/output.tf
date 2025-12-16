output "namespace_id" {
  value = azurerm_servicebus_namespace.sb_namespace.id
}

output "namespace_name" {
  value = azurerm_servicebus_namespace.sb_namespace.name
}

output "namespace_principal_id" {
  description = "Managed identity principal ID of the SB namespace"
  value       = azurerm_servicebus_namespace.sb_namespace.identity[0].principal_id
}

output "queue_ids" {
  value = { for k, q in azurerm_servicebus_queue.queues : k => q.id }
}

output "topic_ids" {
  value = { for k, t in azurerm_servicebus_topic.topics : k => t.id }
}

output "id" {
  value = azurerm_servicebus_namespace.sb_namespace.id
}
