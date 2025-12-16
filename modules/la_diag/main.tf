resource "azurerm_monitor_diagnostic_setting" "diag_to_law" {
  for_each = var.diagnostic_map

  name               = each.value.name
  target_resource_id = each.value.target_resource_id

  # Destinations: default to module-level LA workspace, allow per-item overrides
  log_analytics_workspace_id   = coalesce(try(each.value.destination.log_analytics_workspace_id, null), var.log_analytics_workspace_id)
  storage_account_id           = try(each.value.destination.storage_account_id, null)
  eventhub_name                = try(each.value.destination.eventhub_name, null)
  eventhub_authorization_rule_id = try(each.value.destination.eventhub_authorization_rule_id, null)

  # Logs (enabled_log blocks)
  dynamic "enabled_log" {
    for_each = length(try(each.value.log_categories, [])) > 0 ? each.value.log_categories : var.default_log_categories
    content {
      category = enabled_log.value
      retention_policy {
        enabled = var.default_log_retention_enabled
        days    = var.default_log_retention_days
      }
    }
  }

  # Metrics (metric blocks)
  dynamic "metric" {
    for_each = length(try(each.value.metric_categories, [])) > 0 ? each.value.metric_categories : var.default_metric_categories
    content {
      category = metric.value
      enabled  = true
      retention_policy {
        enabled = var.default_metric_retention_enabled
        days    = var.default_metric_retention_days
      }
    }
  }
}
