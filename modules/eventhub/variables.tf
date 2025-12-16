variable "name" {
  description = "Event Hubs Namespace name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "sku" {
  description = "SKU: Basic | Standard | Premium | Dedicated."
  type        = string
  default     = "Standard"
}

variable "capacity" {
  description = "Throughput units (varies by SKU)."
  type        = number
  default     = 1
}

variable "kafka_enabled" {
  description = "Expose Kafka endpoint compatibility."
  type        = bool
  default     = false
}

variable "auto_inflate_enabled" {
  description = "Enable auto-inflate for throughput units."
  type        = bool
  default     = false
}

variable "maximum_throughput_units" {
  description = "Max TUs when auto-inflate is enabled."
  type        = number
  default     = 0
}

variable "public_network_access_enabled" {
  description = "Allow public network access."
  type        = bool
  default     = true
}

variable "minimum_tls_version" {
  description = "Minimum TLS version (e.g., 1.2)."
  type        = string
  default     = "1.2"
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}

variable "create_namespace_auth_rule" {
  description = "Create a namespace-level SAS authorization rule for connection strings."
  type        = bool
  default     = true
}

variable "namespace_auth_rule_name" {
  description = "Name of the namespace-level SAS authorization rule."
  type        = string
  default     = "app-access"
}

variable "namespace_auth_rule_rights" {
  description = "Rights for the namespace auth rule: any of Listen, Send, Manage."
  type        = list(string)
  default     = ["Listen", "Send"]
  validation {
    condition = length(setsubtract(var.namespace_auth_rule_rights, ["Listen","Send","Manage"])) == 0
    error_message = "namespace_auth_rule_rights must be a subset of [Listen, Send, Manage]."
  }
}