variable "resource_group_name" {
  description = "Resource group for the Cosmos DB account."
  type        = string
}

variable "location" {
  description = "Primary Azure region for the Cosmos DB account."
  type        = string
}

variable "account_name" {
  description = "Cosmos DB account name."
  type        = string
}

variable "kind" {
  description = "Cosmos kind (e.g., GlobalDocumentDB, MongoDB, Parse)."
  type        = string
  default     = "GlobalDocumentDB"
}

variable "enable_system_assigned_identity" {
  description = "Attach a system-assigned identity."
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access."
  type        = bool
  default     = false
}

variable "is_virtual_network_filter_enabled" {
  description = "Enable VNet filter."
  type        = bool
  default     = true
}

variable "local_authentication_disabled" {
  description = "Disable keys (prefer AAD)."
  type        = bool
  default     = true
}

variable "key_vault_key_id" {
  description = "Versionless Key Vault Key ID for CMK (optional)."
  type        = string
  default     = null
}

# Consistency
variable "consistency_level" {
  description = "Strong | BoundedStaleness | Session | ConsistentPrefix | Eventual."
  type        = string
  default     = "Session"
  validation {
    condition     = contains(["Strong","BoundedStaleness","Session","ConsistentPrefix","Eventual"], var.consistency_level)
    error_message = "Invalid consistency level."
  }
}

variable "max_interval_in_seconds" {
  description = "For BoundedStaleness only."
  type        = number
  default     = 5
}

variable "max_staleness_prefix" {
  description = "For BoundedStaleness only."
  type        = number
  default     = 100
}

variable "geo_locations" {
  description = "List of geo locations (first one is primary)."
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool)
  }))
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
