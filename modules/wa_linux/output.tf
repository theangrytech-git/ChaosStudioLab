output "web_app_id" {
  value = azurerm_linux_web_app.wa_linux.id
}

output "web_app_name" {
  value = azurerm_linux_web_app.wa_linux.name
}

output "default_hostname" {
  value = azurerm_linux_web_app.wa_linux.default_hostname
}
