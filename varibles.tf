# variable "subscription_id" {
#   type = string
# }

# variable "environment_tag" {
#   type        = string
#   description = "Environment tag value"
# }

# variable "owner_tag" {
#   type        = string
#   description = "Owner tag value"
# }

# variable "health_tag" {
#   type        = string
#   description = "Health tag value"
# }

# variable "labname" {
#   type        = string
#   description = "Lab name"
# }
# variable "uks" {
#   description = "The location for this Lab environment"
#   type        = string
# }

# # variable "ukw" {
# #   description = "The location for this Lab environment"
# #   type        = string
# # }

# variable "ukscidr" {
#   description = "CIDR range for Region 1"
#   type        = string
# }

# # variable "ukwcidr" {
# #   description = "CIDR range for Region 2"
# #   type        = string
# # }

variable "servercounta" {
  description = "Number of Servers in the Lab A"
  default        = 2
}
variable "servercountb" {
  description = "Number of Servers in the Lab B"
  default        = 3
}

# variable vmsscounta {
#   description = "Number of Scale Sets in VMSS A"
#   type = string
# }

# variable "ukscode" {
#   description = "Server Naming Code for Region 1"
#   type        = string
# }

# # variable "ukwcode" {
# #   description = "Server Naming Code for Region 2"
# #   type        = string
# # }

# variable "uksaccounttier" {
#   description = "Account Tier for Region 1"
#   type        = string
# }

# variable "uksart" {
#   description = "Account Replication Type for Region 1"
#   type        = string
# }

# variable "uks-asp-os" {
#   description = "ASP OS Type for Region 1"
#   type        = string
# }

# variable "uks-asp-sku" {
#   description = "ASP SKU type"
#   type = string
# }

variable "days_to_expire" {
  description = "Days until Secret/Cert expire"
  default = 7
}

# variable "agent_ip" {
#   description = "Azure DevOps agent public IP"
#   type        = string
#   default = ""
# }

# variable "pipeline_sp_object_id" {
#   description = "Service Principal Object ID for Azure DevOps Pipeline"
#   type        = string
#   default     = ""
# }