variable "name" {
  description = "Name of the Application Insights instance"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the resource"
  type        = string
}

variable "application_type" {
  description = "Type of Application Insights (e.g., 'web', 'other')"
  type        = string
  default     = "web"
}

variable "workspace_id" {
  description = "Optional Log Analytics Workspace ID for workspace-based mode"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
