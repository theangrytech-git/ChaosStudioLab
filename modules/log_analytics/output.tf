output "id" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.id
  description = "Resource ID of the workspace."
}

output "workspace_id" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.workspace_id
  description = "Workspace GUID."
}

output "primary_shared_key" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  value       = azurerm_log_analytics_workspace.log_analytics_workspace.secondary_shared_key
  sensitive   = true
}