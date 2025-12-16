resource "azurerm_key_vault" "uks_kv" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = var.sku_name
  purge_protection_enabled    = var.purge_protection_enabled
  enable_rbac_authorization   = var.enable_rbac_authorization
  tags                        = var.tags
  soft_delete_retention_days = 7

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Allow"
  }
}

resource "azurerm_key_vault_access_policy" "kv_access_policy" {
  count = var.enable_rbac_authorization ? 0 : length(var.access_policies)

  key_vault_id = azurerm_key_vault.uks_kv.id

  tenant_id = var.access_policies[count.index].tenant_id
  object_id = var.access_policies[count.index].object_id

  key_permissions         = var.access_policies[count.index].key_permissions
  secret_permissions      = var.access_policies[count.index].secret_permissions
  certificate_permissions = var.access_policies[count.index].certificate_permissions
  storage_permissions     = var.access_policies[count.index].storage_permissions
}