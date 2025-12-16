output "id" {
  value = azurerm_app_configuration.appconfig.id
}

output "name" {
  value = azurerm_app_configuration.appconfig.name
}

output "endpoint" {
  value = azurerm_app_configuration.appconfig.endpoint
}

output "key_values" {
  description = "Echo the input key-values so callers can reference them"
  value       = var.key_values
}