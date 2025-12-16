variable "name" {
  description = "Name of the VM"
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

variable "subnet_id" {
  description = "Subnet ID to place the VM in"
  type        = string
}

variable "vm_size" {
  description = "Size of the Linux VM"
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "public_ip_enabled" {
  description = "Enable or disable a public IP"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the VM and resources"
  type        = map(string)
  default     = {}
}

variable "image" {
  description = "Linux image configuration"
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

variable "availability_set_id" {
  description = "The ID of the availability set to associate the Linux VM with (optional)."
  type        = string
  default     = null
}