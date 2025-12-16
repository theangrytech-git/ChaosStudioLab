resource "azurerm_log_analytics_workspace" "log_analytics_workspace" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  daily_quota_gb        = var.daily_quota_gb               # 0 = unlimited
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  tags                = var.tags
}