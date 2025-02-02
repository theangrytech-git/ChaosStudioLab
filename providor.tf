terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.16.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.3"
    }
  }
}
# Configuration options
provider "azurerm" {
  subscription_id = "b055686f-a26e-43f3-971e-f03a89a7979f"
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

  }
}

provider "azuread" {}

provider "random" {
  # Configuration options
}