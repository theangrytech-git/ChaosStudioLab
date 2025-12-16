resource "azurerm_eventhub_namespace" "eventhub" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Core sizing
  sku      = var.sku
  capacity = var.capacity

  # Useful, safe defaults (optional)
  auto_inflate_enabled          = var.auto_inflate_enabled
  maximum_throughput_units      = var.maximum_throughput_units
  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = var.minimum_tls_version

  tags = var.tags
}

resource "azurerm_eventhub_namespace_authorization_rule" "ns_sas" {
  count               = var.create_namespace_auth_rule ? 1 : 0
  name                = var.namespace_auth_rule_name
  namespace_name      = azurerm_eventhub_namespace.eventhub.name
  resource_group_name = var.resource_group_name

  listen = contains(var.namespace_auth_rule_rights, "Listen")
  send   = contains(var.namespace_auth_rule_rights, "Send")
  manage = contains(var.namespace_auth_rule_rights, "Manage")
}