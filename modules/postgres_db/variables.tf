variable "name" {
  description = "The name of the PostgreSQL flexible server."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The Azure region to deploy to."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the PostgreSQL server."
  type        = string
}

variable "admin_password" {
  description = "Admin password for the PostgreSQL server."
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "The SKU for the PostgreSQL server."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "db_version" {
  description = "PostgreSQL version to use."
  type        = string
  default     = "14"
}

variable "db_names" {
  description = "List of database names to create on the server"
  type        = list(string)
}

variable "subnet_id" {
  description = "The delegated subnet ID for private access."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for PostgreSQL."
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
