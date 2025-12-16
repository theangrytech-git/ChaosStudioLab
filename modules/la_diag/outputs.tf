output "diagnostic_setting_ids" {
  description = "Map of diagnostic setting IDs keyed by the provided map keys."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.diag_to_law : k => v.id }
}

output "diagnostic_setting_names" {
  description = "Map of diagnostic setting names keyed by the provided map keys."
  value       = { for k, v in azurerm_monitor_diagnostic_setting.diag_to_law : k => v.name }
}
