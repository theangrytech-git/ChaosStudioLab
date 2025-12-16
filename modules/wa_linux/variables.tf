variable "name" {
  description = "Name of the Web App"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "app_service_plan_id" {
  description = "ID of the App Service Plan"
  type        = string
}

variable "runtime" {
  description = "Runtime stack (e.g., python, node, php)"
  type        = string
}

variable "runtime_version" {
  description = "Version of the runtime (e.g., 3.10 for Python)"
  type        = string
}

variable "app_settings" {
  description = "Additional app settings"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to the resource"
  type        = map(string)
  default     = {}
}
