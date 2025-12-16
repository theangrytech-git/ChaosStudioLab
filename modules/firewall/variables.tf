variable "name" {
  description = "Azure Firewall name"
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

# SKU
variable "sku_name" {
  description = "Firewall SKU name. For VNet it's AZFW_VNet"
  type        = string
  default     = "AZFW_VNet"
}

variable "sku_tier" {
  description = "Firewall SKU tier: Basic, Standard, Premium"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be one of: Basic, Standard, Premium."
  }
}

variable "threat_intel_mode" {
  description = "Threat intel mode: Alert, Deny, or Off"
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Alert", "Deny", "Off"], var.threat_intel_mode)
    error_message = "threat_intel_mode must be Alert, Deny, or Off."
  }
}

# Public IP handling (primary dataplane IP)
variable "create_public_ip" {
  description = "Create a new Public IP for the firewall"
  type        = bool
  default     = true
}

variable "public_ip_id" {
  description = "Use an existing Public IP ID (overrides create_public_ip)"
  type        = string
  default     = null
}

variable "public_ip_name" {
  description = "Name for created Public IP (when create_public_ip = true)"
  type        = string
  default     = null
}

variable "public_ip_sku" {
  description = "SKU for created Public IP"
  type        = string
  default     = "Standard"
}

variable "public_ip_allocation" {
  description = "Allocation for created Public IP"
  type        = string
  default     = "Static"
}

variable "public_ip_zones" {
  description = "Zones for created Public IP (or null)"
  type        = list(string)
  default     = null
}

variable "public_ip_domain_label" {
  description = "Optional domain_name_label for created PIP"
  type        = string
  default     = null
}

# Management IP (required for Basic SKU)
variable "create_management_ip" {
  description = "Create a management Public IP (required for Basic SKU)"
  type        = bool
  default     = false
}

variable "management_public_ip_id" {
  description = "Existing management Public IP ID (overrides create_management_ip)"
  type        = string
  default     = null
}

variable "management_public_ip_name" {
  description = "Name for created management Public IP"
  type        = string
  default     = null
}

# IP Configurations (at least one). First item is used for the dataplane + PIP.
variable "ip_configurations" {
  description = <<EOT
List of firewall IP configurations. The first entry is used for the primary dataplane IP config.
Each object: { name = string, subnet_id = string }
EOT
  type = list(object({
    name      = string
    subnet_id = string
  }))
}

# Optional rule collections

variable "network_rule_collections" {
  description = <<EOT
Map of network rule collections.
{
  coll1 = {
    name     = string
    priority = number
    action   = string               # Allow or Deny
    rules = [
      {
        name                  = string
        source_addresses      = list(string)
        destination_addresses = list(string)
        destination_fqdns     = optional(list(string))
        destination_ports     = list(string)
        protocols             = list(string) # TCP/UDP/Any
      },
      ...
    ]
  },
  ...
}
EOT
  type = map(object({
    name     = string
    priority = number
    action   = string
    rules    = list(object({
      name                  = string
      source_addresses      = list(string)
      destination_addresses = optional(list(string))
      destination_fqdns     = optional(list(string))
      destination_ports     = list(string)
      protocols             = list(string)
    }))
  }))
  default = {}
}

variable "application_rule_collections" {
  description = <<EOT
Map of application rule collections.
{
  coll1 = {
    name     = string
    priority = number
    action   = string               # Allow or Deny
    rules = [
      {
        name             = string
        source_addresses = list(string)
        fqdn_tags        = optional(list(string))
        target_fqdns     = optional(list(string))
        protocols        = list(object({ type = string, port = number })) # Http/Https/Mssql
      },
      ...
    ]
  },
  ...
}
EOT
  type = map(object({
    name     = string
    priority = number
    action   = string
    rules    = list(object({
      name             = string
      source_addresses = list(string)
      fqdn_tags        = optional(list(string))
      target_fqdns     = optional(list(string))
      protocols        = list(object({
        type = string
        port = number
      }))
    }))
  }))
  default = {}
}

variable "nat_rule_collections" {
  description = "Map of NAT rule collections (destination_addresses optional; if omitted, module may use its own PIP)"
  type = map(object({
    name     = string
    priority = number
    action   = string   # Dnat
    rules    = list(object({
      name                  = string
      source_addresses      = list(string)
      destination_addresses = optional(list(string))   # <-- was required; now optional
      destination_ports     = list(string)
      translated_address    = string
      translated_port       = string
      protocols             = list(string)
    }))
  }))
  default = {}
}
