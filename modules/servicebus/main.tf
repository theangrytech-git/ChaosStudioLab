resource "azurerm_servicebus_namespace" "sb_namespace" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku

  public_network_access_enabled = var.public_network_access_enabled
  minimum_tls_version           = var.minimum_tls_version

  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? var.identity_ids : null
  }

  tags = var.tags
}

# Queues
resource "azurerm_servicebus_queue" "queues" {
  for_each     = { for q in var.queues : q.name => q }
  name         = each.value.name
  namespace_id = azurerm_servicebus_namespace.sb_namespace.id

  # Standard/Premium support partitioning
  partitioning_enabled = try(each.value.partitioning_enabled, true)

  depends_on = [azurerm_servicebus_namespace.sb_namespace]
}

# Topics
resource "azurerm_servicebus_topic" "topics" {
  for_each     = { for t in var.topics : t.name => t }
  name         = each.value.name
  namespace_id = azurerm_servicebus_namespace.sb_namespace.id

  partitioning_enabled = try(each.value.partitioning_enabled, true)

  depends_on = [azurerm_servicebus_namespace.sb_namespace]
}
