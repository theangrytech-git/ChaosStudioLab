variable "name" {
  description = "Name of the Key Vault"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group for the Key Vault"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "sku_name" {
  description = "SKU for Key Vault"
  type        = string
  default     = "standard"
}

variable "purge_protection_enabled" {
  type    = bool
  default = false
}

variable "enable_rbac_authorization" {
  description = "Whether to use RBAC instead of access policies"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for the Key Vault"
  type        = map(string)
  default     = {}
}

variable "access_policies" {
  description = "List of access policies"
  type = list(object({
    tenant_id               = string
    object_id               = string
    key_permissions         = list(string)
    secret_permissions      = list(string)
    certificate_permissions = list(string)
    storage_permissions     = list(string)
  }))
  default = []
}
