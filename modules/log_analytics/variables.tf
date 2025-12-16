variable "name" {
  description = "Log Analytics workspace name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "sku" {
  description = "SKU: PerGB2018 | Free | Standalone | CapacityReservation."
  type        = string
  default     = "PerGB2018"
  validation {
    condition     = contains(["PerGB2018","Free","Standalone","CapacityReservation"], var.sku)
    error_message = "sku must be one of: PerGB2018, Free, Standalone, CapacityReservation."
  }
}

variable "retention_in_days" {
  description = "Retention in days (30–730 for PerGB2018)."
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily ingestion cap in GB (0 = unlimited)."
  type        = number
  default     = 0
}

variable "internet_ingestion_enabled" {
  description = "Allow ingestion over public internet."
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Allow queries over public internet."
  type        = bool
  default     = true
}

variable "reservation_capacity_in_gb_per_day" {
  description = "Capacity reservation (GB/day). Only for CapacityReservation SKU."
  type        = number
  default     = null
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
