variable "log_analytics_workspace_id" {
  description = "Default Log Analytics workspace ID for all diagnostic settings (can be overridden per item)."
  type        = string
}

variable "default_log_categories" {
  description = "Default log categories when an item doesn't specify any."
  type        = list(string)
  default     = [] # e.g., ["OperationalLogs"] for SB/EventHub, ["AuditEvent"] for Key Vault, etc.
}

variable "default_metric_categories" {
  description = "Default metric categories when an item doesn't specify any."
  type        = list(string)
  default     = ["AllMetrics"]
}

variable "default_log_retention_enabled" {
  description = "Enable retention for log categories (applies to every enabled_log block)."
  type        = bool
  default     = false
}

variable "default_log_retention_days" {
  description = "Retention days for log categories."
  type        = number
  default     = 0
}

variable "default_metric_retention_enabled" {
  description = "Enable retention for metric categories."
  type        = bool
  default     = false
}

variable "default_metric_retention_days" {
  description = "Retention days for metric categories."
  type        = number
  default     = 0
}

variable "diagnostic_map" {
  description = <<EOT
Map of diagnostic settings to create. Key is an arbitrary handle.
- name: Name of the diagnostic setting
- target_resource_id: Resource ID to attach diagnostics to
- log_categories: Optional list of log categories
- metric_categories: Optional list of metric categories
- destination: Optional overrides for destinations

Example:
{
  cosmosdb = {
    name                = "cosmosdb-diag"
    target_resource_id  = azurerm_cosmosdb_account.cs_cosmosdb.id
    log_categories      = ["DataPlaneRequests"]
    metric_categories   = ["AllMetrics"]
  }
}
EOT
  type = map(object({
    name               = string
    target_resource_id = string
    log_categories     = optional(list(string), [])
    metric_categories  = optional(list(string), [])
    destination = optional(object({
      log_analytics_workspace_id    = optional(string)
      storage_account_id            = optional(string)
      eventhub_name                 = optional(string)
      eventhub_authorization_rule_id= optional(string)
      marketplace_partner_id        = optional(string)
    }), null)
  }))
  default = {}
}
