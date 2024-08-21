variable "environment_tag" {
  type        = string
  description = "Environment tag value"
}

variable "owner_tag" {
  type        = string
  description = "Owner tag value"
}

variable "labname" {
  type        = string
  description = "Lab name"
}
variable "region1" {
  description = "The location for this Lab environment"
  type        = string
}

variable "region2" {
  description = "The location for this Lab environment"
  type        = string
}

variable "region1cidr" {
  description = "CIDR range for Region 1"
  type        = string
}

variable "region2cidr" {
  description = "CIDR range for Region 2"
  type        = string
}

variable "servercounta" {
  description = "Number of Servers in the Lab A"
  type        = string
}
variable "servercountb" {
  description = "Number of Servers in the Lab B"
  type        = string
}

variable "region1code" {
  description = "Server Naming Code for Region 1"
  type        = string
}

variable "region2code" {
  description = "Server Naming Code for Region 2"
  type        = string
}

variable "region1accounttier" {
  description = "Account Tier for Region 1"
  type        = string
}

variable "region1art" {
  description = "Account Replication Type for Region 1"
  type        = string
}

variable "region1-asp-os" {
  description = "ASP OS Type for Region 1"
  type        = string
}

variable "region1-asp-sku" {
  description = "ASP SKU type"
  type = string
}

variable "days_to_expire" {
  description = "Days until Secret/Cert expire"
  type = number
}
