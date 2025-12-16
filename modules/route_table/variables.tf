variable "name" {
  description = "Name of the route table"
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

variable "routes" {
  description = "List of routes to create"
  type = list(object({
    name                   = string
    address_prefix         = string
    next_hop_type          = string
    next_hop_in_ip_address = optional(string)
  }))
}

variable "subnet_ids" {
  description = "Map of subnet names to IDs for association"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags for the route table"
  type        = map(string)
  default     = {}
}