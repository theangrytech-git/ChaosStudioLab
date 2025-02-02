variable "environment_tag" {
  type        = string
  description = "Environment tag value"
}

variable "owner_tag" {
  type        = string
  description = "Owner tag value"
}

variable "health_tag" {
  type        = string
  description = "Health tag value"
}

variable "labname" {
  type        = string
  description = "Lab name"
}
variable "uks" {
  description = "The location for this Lab environment"
  type        = string
}

# variable "ukw" {
#   description = "The location for this Lab environment"
#   type        = string
# }

variable "ukscidr" {
  description = "CIDR range for Region 1"
  type        = string
}

# variable "ukwcidr" {
#   description = "CIDR range for Region 2"
#   type        = string
# }

variable "servercounta" {
  description = "Number of Servers in the Lab A"
  type        = string
}
variable "servercountb" {
  description = "Number of Servers in the Lab B"
  type        = string
}

variable vmsscounta {
  description = "Number of Scale Sets in VMSS A"
  type = string
}

variable "ukscode" {
  description = "Server Naming Code for Region 1"
  type        = string
}

# variable "ukwcode" {
#   description = "Server Naming Code for Region 2"
#   type        = string
# }

variable "uksaccounttier" {
  description = "Account Tier for Region 1"
  type        = string
}

variable "uksart" {
  description = "Account Replication Type for Region 1"
  type        = string
}

variable "uks-asp-os" {
  description = "ASP OS Type for Region 1"
  type        = string
}

variable "uks-asp-sku" {
  description = "ASP SKU type"
  type = string
}

variable "days_to_expire" {
  description = "Days until Secret/Cert expire"
  type = number
}

variable "cosmos_databases" {
  type = map(object({
    collections = list(string)
  }))
  default = {
    super_secret_stuff = { collections = ["users", "accountnumber", "transactions"] }
    banking_stuff      = { collections = ["balance", "loans", "accounts"] }
    secret_pid         = { collections = ["classified", "name", "address", "logs"] }
  }
}

variable "servicebus_queues" {
  type = map(object({
    max_delivery_count = number
    enable_partitioning = bool
  }))
  default = {
    email_notifications = { max_delivery_count = 10, enable_partitioning = true }
    task_processing     = { max_delivery_count = 5, enable_partitioning = false }
  }
}

variable "event_hubs" {
  type = map(object({
    partitions = number
    message_retention = number
  }))
  default = {
    event_alerts = { partitions = 2, message_retention = 7 }
    system_logs  = { partitions = 4, message_retention = 14 }
  }
}