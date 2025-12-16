resource "azurerm_private_endpoint" "private_endpoint" {
  for_each            = { for conn in var.connections : conn.name => conn }
  name                = "${var.name}-${each.value.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    for sc in each.value.subresource_names : sc => {
      name                           = "${each.value.name}-${sc}"
      private_connection_resource_id = each.value.private_connection_resource_id
      subresource_names              = [sc]
      is_manual_connection           = false
    }
  }

  tags = {
    environment = "training"
  }
}

# Link Private DNS Zones if provided
resource "azurerm_private_dns_zone_virtual_network_link" "dns_links" {
  for_each = toset(var.private_dns_zone_ids)
  name                = "${azurerm_private_endpoint.this[values(var.connections)[0].name].name}-dnslink"
  resource_group_name = var.resource_group_name
  virtual_network_id  = var.subnet_id # VNet ID required
  private_dns_zone_id = each.value
  depends_on          = [azurerm_private_endpoint.this]
}
