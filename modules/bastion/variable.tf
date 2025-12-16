variable "name" {
  description = "Name of the Bastion Host"
  type        = string
}

# variable "dns_name" {
#   description = "Optional custom DNS name for Bastion (optional)"
#   type        = string
#   default     = null
# }

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the Bastion will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID for the AzureBastionSubnet"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
