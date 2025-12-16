resource "azurerm_monitor_diagnostic_setting" "diag" {
  name                       = var.name
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.log_categories
    content {
      category = enabled_log.value
      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }

  dynamic "metric" {
    for_each = var.metric_categories
    content {
      category = metric.value
      retention_policy {
        enabled = false
        days    = 0
      }
    }
  }
}
