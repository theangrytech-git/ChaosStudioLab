resource "azurerm_postgresql_flexible_server" "pg_server" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  sku_name               = var.sku_name
  version                = var.db_version
  storage_mb             = 32768
  zone                   = "1"
  delegated_subnet_id    = var.subnet_id
  private_dns_zone_id    = var.private_dns_zone_id
  public_network_access_enabled = false

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "pg_db" {
  for_each = toset(var.db_names)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.pg_server.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
