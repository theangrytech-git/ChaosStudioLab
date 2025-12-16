resource "azurerm_storage_account" "uks_storage_account" {
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_tier                     = var.account_tier
  account_replication_type         = var.replication_type
  account_kind                     = var.account_kind
  access_tier                      = var.access_tier
  min_tls_version                  = var.min_tls_version
  #enable_https_traffic_only        = var.enable_https_traffic_only
  public_network_access_enabled    = var.public_network_access_enabled
  shared_access_key_enabled        = var.shared_access_key_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  allow_nested_items_to_be_public  = false
  #allow_blob_public_access         = false

  dynamic "identity" {
    for_each = var.identity_type == null ? [] : [1]
    content {
      type = var.identity_type
    }
  }

  dynamic "sas_policy" {
    for_each = var.sas_expiration_period == null ? [] : [1]
    content {
      expiration_period = var.sas_expiration_period
    }
  }

  dynamic "blob_properties" {
    for_each = (var.blob_soft_delete_days != null
             || var.container_delete_retention_days != null
             || var.versioning_enabled != null
             || var.change_feed_enabled != null) ? [1] : []
    content {
      dynamic "delete_retention_policy" {
        for_each = var.blob_soft_delete_days == null ? [] : [1]
        content { days = var.blob_soft_delete_days }
      }
      versioning_enabled = var.versioning_enabled
      change_feed_enabled = var.change_feed_enabled
      dynamic "container_delete_retention_policy" {
        for_each = var.container_delete_retention_days == null ? [] : [1]
        content { days = var.container_delete_retention_days }
      }
    }
  }

  dynamic "network_rules" {
  for_each = (
    var.network_default_action != null
    || length(var.network_bypass) > 0
    || length(var.ip_rules) > 0
    || length(var.subnet_ids) > 0
  ) ? [1] : []

  content {
    default_action              = var.network_default_action
    bypass                      = var.network_bypass
    ip_rules                    = var.ip_rules
    virtual_network_subnet_ids  = var.subnet_ids
  }
}

  tags = var.tags
}
