variable "name" {
  description = "Container group name"
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

variable "os_type" {
  description = "OS type (Linux or Windows)"
  type        = string
  default     = "Linux"
}

variable "ip_address_type" {
  description = "IP type (Public or Private)"
  type        = string
  default     = "Public"
}

variable "dns_name_label" {
  description = "DNS label for public access (if IP type is Public)"
  type        = string
  default     = null
}

variable "restart_policy" {
  description = "Restart policy (Always, Never, OnFailure)"
  type        = string
  default     = "Always"
}

variable "container_name" {
  description = "Name of the container instance"
  type        = string
}

variable "image" {
  description = "Container image name (e.g., nginx:latest)"
  type        = string
}

variable "cpu" {
  description = "CPU cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in GB"
  type        = number
  default     = 1.5
}

variable "port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
