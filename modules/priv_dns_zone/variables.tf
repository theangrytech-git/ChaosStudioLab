variable "zone_name" {
  description = "The name of the Private DNS Zone (e.g., 'postgres.database.azure.com')"
  type        = string
}

variable "resource_group_name" {
  description = "The resource group where the Private DNS Zone will be created"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Private DNS Zone"
  type        = map(string)
  default     = {}
}

variable "virtual_network_links" {
  description = "A map of VNet names to VNet IDs to link to the DNS zone"
  type        = map(string)
  default     = {}
}