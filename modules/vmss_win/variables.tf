variable "name" {
  type        = string
  description = "VMSS name"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the VMSS"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID to deploy VMSS into"
}

variable "vm_sku" {
  type        = string
  description = "VM size"
  default     = "Standard_B2s"
}

variable "instance_count" {
  type        = number
  description = "Number of instances"
  default     = 2
}

variable "admin_username" {
  type        = string
  description = "Admin username"
}

variable "admin_password" {
  type        = string
  description = "Admin password"
  sensitive   = true
}

variable "computer_name_prefix" {
  type        = string
  description = "Computer name prefix"
  default     = "vmss"
}

variable "tags" {
  type        = map(string)
  description = "Tags"
  default     = {}
}

variable "image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Image reference"
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
