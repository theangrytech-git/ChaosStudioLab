variable "location" {
  type        = string
  description = "Azure region (e.g., uksouth)."
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for the LB."
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID for the LB frontend."
}

variable "vnet_cidr" {
  type        = string
  description = "CIDR of the VNet to compute the LB private IP."
}

variable "lb_offset" {
  type        = number
  description = "Offset used with cidrhost() for the LB private IP."
  default     = 260
}

variable "lb_name" {
  type        = string
  description = "Optional explicit LB name. Defaults to lb-int-<location>."
  default     = null
}

variable "frontend_name" {
  type        = string
  description = "Optional explicit frontend IP config name."
  default     = null
}

variable "backend_pool_name" {
  type        = string
  description = "Backend pool name."
  default     = "BackEndAddressPool"
}

variable "probe_name" {
  type        = string
  description = "Probe name."
  default     = "http-probe"
}

variable "probe_port" {
  type        = number
  description = "Probe port."
  default     = 80
}

variable "probe_protocol" {
  type        = string
  description = "Probe protocol: Http or Tcp."
  default     = "Http"
  validation {
    condition     = contains(["Http", "Tcp"], var.probe_protocol)
    error_message = "probe_protocol must be 'Http' or 'Tcp'."
  }
}

variable "probe_interval" {
  type        = number
  description = "Probe interval in seconds."
  default     = 60
}

variable "probe_request_path" {
  type        = string
  description = "HTTP probe request path (only when protocol is Http)."
  default     = "/"
}

variable "rule_name" {
  type        = string
  description = "LB rule name."
  default     = "LBRule"
}

variable "rule_protocol" {
  type        = string
  description = "LB rule protocol."
  default     = "Tcp"
}

variable "frontend_port" {
  type        = number
  description = "Frontend port exposed by the LB."
  default     = 80
}

variable "backend_port" {
  type        = number
  description = "Backend (VM) port."
  default     = 80
}

# Pass any number of NICs with their IP configuration names
variable "nic_associations" {
  description = "List of NIC associations to add to backend pool."
  type = list(object({
    nic_id               : string
    ip_configuration_name: string
  }))
  default = []
}
