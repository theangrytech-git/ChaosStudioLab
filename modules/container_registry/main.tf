resource "azurerm_container_registry" "container_registry" {
  name                     = var.name
  location                 = var.location
  resource_group_name      = var.resource_group_name
  sku                      = var.sku
  admin_enabled            = var.admin_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                     = var.tags
}
