variable "name" {
  description = "Base name for the private endpoint"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the private endpoint will be deployed"
  type        = string
}

variable "private_dns_zone_ids" {
  description = "List of Private DNS Zone IDs to link to the private endpoint"
  type        = list(string)
  default     = []
}

variable "connections" {
  description = <<EOT
List of connections for the private endpoint. Each object must have:
- name: name of the connection
- private_connection_resource_id: the resource ID of the target resource
- subresource_names: list of subresources to connect (e.g., ["vault", "blob"])
EOT
  type = list(object({
    name                           = string
    private_connection_resource_id = string
    subresource_names              = list(string)
  }))
}
