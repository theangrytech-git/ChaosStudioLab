output "id" {
  value       = azurerm_cosmosdb_account.cosmosdb.id
  description = "Cosmos DB account resource ID."
}

output "name" {
  value       = azurerm_cosmosdb_account.cosmosdb.name
  description = "Cosmos DB account name."
}

output "endpoint" {
  value       = azurerm_cosmosdb_account.cosmosdb.endpoint
  description = "Primary document endpoint."
}
