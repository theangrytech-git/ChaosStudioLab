output "name" {
  value = azurerm_storage_account.uks_storage_account.name
}

output "id" {
  value = azurerm_storage_account.uks_storage_account.id
}

output "primary_access_key" {
  value     = azurerm_storage_account.uks_storage_account.primary_access_key
  sensitive = true
}
