output "id" {
  value = azurerm_container_registry.container_registry.id
}

output "login_server" {
  value = azurerm_container_registry.container_registry.login_server
}

output "admin_username" {
  value = var.admin_enabled ? azurerm_container_registry.container_registry.admin_username : null
}

output "admin_password" {
  value = var.admin_enabled ? azurerm_container_registry.container_registry.admin_password : null
}

output "name" {
  value = azurerm_container_registry.container_registry.name
}
