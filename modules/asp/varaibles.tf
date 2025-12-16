variable "name" {
  type        = string
  description = "App Service Plan name (must be unique in RG)."
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "os_type" {
  type        = string
  description = "Windows or Linux."
  validation {
    condition     = contains(["Windows", "Linux"], var.os_type)
    error_message = "os_type must be 'Windows' or 'Linux'."
  }
}

variable "sku_name" {
  type        = string
  description = "Plan SKU, e.g. P1v3, S1, B1, Y1 (Functions), EP1."
}

variable "zone_balancing_enabled" {
  type        = bool
  default     = false
  description = "Distribute workers across zones (where supported)."
}

variable "worker_count" {
  type        = number
  default     = null
  description = "Dedicated workers count (App Service: S/B/P plans)."
}

variable "maximum_elastic_worker_count" {
  type        = number
  default     = null
  description = "Max elastic workers (Elastic Premium / some Linux skus)."
}

variable "tags" {
  type    = map(string)
  default = {}
}
