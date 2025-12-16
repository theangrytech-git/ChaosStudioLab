resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = var.account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = var.kind
  offer_type          = "Standard"

  # Identity
  dynamic "identity" {
    for_each = var.enable_system_assigned_identity ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  # Networking & security
  public_network_access_enabled     = var.public_network_access_enabled
  is_virtual_network_filter_enabled = var.is_virtual_network_filter_enabled
  local_authentication_disabled     = var.local_authentication_disabled

  # Optional CMK (must be versionless key ID)
  key_vault_key_id = var.key_vault_key_id

  # Consistency
  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.max_interval_in_seconds
    max_staleness_prefix    = var.max_staleness_prefix
  }

  # Regions: use the list provided by the caller (first entry should be failover_priority = 0)
  dynamic "geo_location" {
    for_each = var.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = try(geo_location.value.zone_redundant, false)
    }
  }

  lifecycle {
    # prevent_destroy = true
    ignore_changes = [
      key_vault_key_id,
    ]
  }

  tags = var.tags
}
