resource "azurerm_app_configuration" "appconfig" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  tags                = var.tags
}

resource "azurerm_app_configuration_key" "appconfig_key" {
  for_each = var.key_values

  configuration_store_id = azurerm_app_configuration.appconfig.id
  key                    = each.key
  value                  = each.value.value
  label                  = try(each.value.label, null)
  content_type           = try(each.value.content_type, null)
  locked                 = try(each.value.locked, false)
  tags                   = try(each.value.tags, null)
}

# data "azurerm_app_configuration_key" "kv" {
#   for_each               = var.key_values
#   configuration_store_id = azurerm_app_configuration.appconfig.id
#   key                    = each.key
# }

resource "azurerm_role_assignment" "data_owner" {
  scope                = azurerm_app_configuration.appconfig.id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = var.principal_id
}