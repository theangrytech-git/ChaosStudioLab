variable "name" {
  description = "Name of the App Configuration store"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where App Configuration is created"
  type        = string
}

variable "sku" {
  description = "SKU (e.g., 'standard')"
  type        = string
  default     = "standard"
}

variable "tags" {
  description = "Tags for the resource"
  type        = map(string)
  default     = {}
}

variable "key_values" {
  description = "Map of App Config keys to create"
  type = map(object({
    value        = string
    label        = optional(string)
    content_type = optional(string)
    locked       = optional(bool, false)
    tags         = optional(map(string), {})
  }))
  default = {}
}
variable "principal_id" {
  type        = string
  description = "Object ID of the identity that needs App Configuration data-plane access (Data Owner)."
}