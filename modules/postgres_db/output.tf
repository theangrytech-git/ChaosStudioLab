output "fqdn" {
  value = azurerm_postgresql_flexible_server.pg_server.fqdn
}

output "admin_username" {
  value = azurerm_postgresql_flexible_server.pg_server.administrator_login
}

output "admin_password" {
  value     = var.admin_password
  sensitive = true
}

output "connection_strings" {
  value = {
    for name in var.db_names :
    name => "Host=${azurerm_postgresql_flexible_server.pg_server.fqdn};Port=5432;Database=${name};Username=${azurerm_postgresql_flexible_server.pg_server.administrator_login};Password=${var.admin_password};SslMode=Require"
  }
  sensitive = true
}

output "database_names" {
  value = [for db in azurerm_postgresql_flexible_server_database.pg_db : db.name]
}

output "id" {
  value = azurerm_postgresql_flexible_server.pg_server.id
}