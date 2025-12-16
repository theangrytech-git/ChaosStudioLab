variable "name" {
  description = "Service Bus namespace name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "sku" {
  description = "Service Bus SKU: Basic, Standard, or Premium"
  type        = string
  default     = "Standard"
}

variable "public_network_access_enabled" {
  description = "Allow public network access"
  type        = bool
  default     = false
}

variable "minimum_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "identity_type" {
  description = "Managed identity type: SystemAssigned or UserAssigned"
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "User-assigned identity IDs (required if identity_type == UserAssigned)"
  type        = list(string)
  default     = []
}

variable "queues" {
  description = "Queues to create"
  type = list(object({
    name                 = string
    partitioning_enabled = optional(bool, true)
  }))
  default = []
}

variable "topics" {
  description = "Topics to create"
  type = list(object({
    name                 = string
    partitioning_enabled = optional(bool, true)
  }))
  default = []
}

variable "existing_key_vault_key_id" {
  description = "Existing Key Vault key ID to use as CMK (when use_existing_key = true)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
