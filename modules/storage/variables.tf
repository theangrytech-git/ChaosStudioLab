variable "name" {
  type = string
  description = "Globally unique storage account name"
  }

variable "resource_group_name" {
  type = string
  description = "Name of the resource group in which to create the storage account"
  }

variable "location" {
  type = string
  description = "Azure region where the storage account will be created"
  }

variable "account_tier" {
  type = string
  default = "Standard"
  description = "The tier of the storage account"
  }

variable "replication_type" {
  type = string
  default = "LRS" # LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS
  description = "The replication type of the storage account"
  }

variable "account_kind" {
  type = string
  default = "StorageV2"
  description = "The Kind of the storage account. Possible values include: Storage, StorageV2, BlobStorage, FileStorage, BlockBlobStorage"
  }

variable "access_tier" {
  type = string
  default = "Hot"
  description = "Access tier for BlobStorage and general purpose v2 accounts"
  }

variable "min_tls_version" {
  type = string
  default = "TLS1_2"
  description = "Minimum TLS version to be permitted on requests to storage"
  }

variable "enable_https_traffic_only" {
  type = bool
  default = true
  description = "Force HTTPS traffic only"
  }

variable "public_network_access_enabled" {
  type = bool
  default = false
  description = "Enable public network access to the storage account"
  }

variable "shared_access_key_enabled" {
  type = bool
  default = true
  description = "Enable shared key access for the storage account"
  }

variable "infrastructure_encryption_enabled" {
  type = bool
  default = true
  description = "Enable infrastructure encryption for the storage account"
  }

variable "identity_type" {
  type = string
  default = null
}

variable "sas_expiration_period" {
  type = string
  default = null
  description = "SAS expiration period, e.g. '1.00:00:00' for 1 day (d.hh:mm:ss)"
  }

variable "blob_soft_delete_days" {
  type = number
  default = 7
  }

variable "container_delete_retention_days" {
  type = number
  default = 7
  description = "Container delete retention period in days"
  }

variable "versioning_enabled" {
  type = bool
  default = true
  description = "Enable versioning for the storage account"
  }

variable "change_feed_enabled" {
  type = bool
  default = true
  description = "Enable change feed for the storage account"
  }

variable "network_default_action" {
  type = string
  default = "Deny"
  description = "Default action for network rules: Allow or Deny"
  }

variable "network_bypass" {
  type = list(string)
  default = ["AzureServices"]
  description = "Bypass options: None, Logging, Metrics, AzureServices"
  }

variable "ip_rules" {
  type = list(string)
  default = []
  description = "List of IP addresses or CIDR ranges"
  }

variable "subnet_ids" {
  type = list(string)
  default = []
  description = "List of subnet resource IDs for VNet rules"
  }

variable "tags" {
  type = map(string)
  default = {}
  description = "Tags to apply to the storage account"
  }
