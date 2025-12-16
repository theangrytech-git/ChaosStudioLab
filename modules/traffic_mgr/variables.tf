variable "profile_name" {
  type        = string
  description = "Name of the Traffic Manager profile (e.g., tm-myapp)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the Traffic Manager profile."
}

variable "traffic_routing_method" {
  type        = string
  description = "Traffic routing method."
  default     = "Weighted"
  validation {
    condition = contains(
      ["Weighted", "Priority", "Performance", "Geographic", "Multivalue", "Subnet"],
      var.traffic_routing_method
    )
    error_message = "traffic_routing_method must be one of: Weighted, Priority, Performance, Geographic, Multivalue, Subnet."
  }
}

variable "relative_name" {
  type        = string
  description = "DNS relative name (label). FQDN will be <relative_name>.trafficmanager.net."
}

variable "ttl" {
  type        = number
  description = "DNS TTL for Traffic Manager profile."
  default     = 100
}

# Monitor config
variable "monitor_protocol" {
  type        = string
  description = "Monitor protocol."
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.monitor_protocol)
    error_message = "monitor_protocol must be HTTP, HTTPS, or TCP."
  }
}

variable "monitor_port" {
  type        = number
  description = "Monitor port."
  default     = 80
}

variable "monitor_path" {
  type        = string
  description = "Monitor path (HTTP/HTTPS only)."
  default     = "/"
}

variable "monitor_interval_in_seconds" {
  type        = number
  description = "Monitor interval in seconds."
  default     = 30
}

variable "monitor_timeout_in_seconds" {
  type        = number
  description = "Monitor timeout in seconds."
  default     = 10
}

variable "monitor_tolerated_number_of_failures" {
  type        = number
  description = "Failures tolerated before marking endpoint degraded."
  default     = 3
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Traffic Manager profile."
  default     = {}
}

variable "public_ip_dns_label"{
  type = string
  description = "DNS label for the Public IP if create_public_ip is true."
  }

# Azure endpoints list
variable "azure_endpoints" {
  description = <<EOT
List of Azure endpoints to attach. Each object:
{
  name               = string                # unique per profile (optional; auto 'ep-<idx>' if empty)
  target_resource_id = string                # e.g. azurerm_public_ip.<name>.id
  enabled            = optional(bool, true)
  weight             = optional(number)      # only used for Weighted
  priority           = optional(number)      # only used for Priority
}
EOT
  type = list(object({
    name               = string
    target_resource_id = string
    enabled            = optional(bool)
    weight             = optional(number)
    priority           = optional(number)
  }))
  default = []
}

variable "create_public_ip" {
  type        = bool
  description = "Create a Public IP and attach it as a Traffic Manager Azure endpoint."
  default     = false
}

variable "public_ip_name" {
  type        = string
  description = "Name of the managed Public IP (required if create_public_ip = true)."
  default     = null
}

variable "public_ip_location" {
  type        = string
  description = "Azure region for the managed Public IP (e.g., uksouth)."
  default     = null
}

variable "public_ip_sku" {
  type        = string
  description = "Public IP SKU."
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Basic"], var.public_ip_sku)
    error_message = "public_ip_sku must be Standard or Basic."
  }
}

variable "public_ip_allocation" {
  type        = string
  description = "Allocation method for the Public IP."
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation)
    error_message = "public_ip_allocation must be Static or Dynamic."
  }
}

variable "public_ip_zones" {
  type        = list(string)
  description = "Optional availability zones for the Public IP (e.g., [\"1\",\"2\",\"3\"])."
  default     = null
}

# Managed endpoint config (for the created Public IP)
variable "managed_endpoint_name" {
  type        = string
  description = "Traffic Manager endpoint name for the managed Public IP."
  default     = "pip-endpoint"
}

variable "managed_endpoint_enabled" {
  type        = bool
  description = "Whether the managed endpoint is enabled."
  default     = true
}

variable "managed_endpoint_weight" {
  type        = number
  description = "Weight for the managed endpoint (Weighted routing only)."
  default     = 100
}

variable "managed_endpoint_priority" {
  type        = number
  description = "Priority for the managed endpoint (Priority routing only; lower is higher priority)."
  default     = null
}