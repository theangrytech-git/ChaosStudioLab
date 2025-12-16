variable "name" {
  description = "The name of the diagnostic setting"
  type        = string
}

variable "target_resource_id" {
  description = "The ID of the resource to attach diagnostics to"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of Log Analytics workspace"
  type        = string
}

variable "log_categories" {
  description = "List of log categories to enable"
  type        = list(string)
  default     = []
}

variable "metric_categories" {
  description = "List of metric categories to enable"
  type        = list(string)
  default     = []
}
