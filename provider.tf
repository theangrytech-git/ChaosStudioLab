terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
  }

  backend "azurerm" {}
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  use_cli         = true
  use_msi         = false
  subscription_id = var.subscription_id
}

provider "random" {
  # No additional configuration required
}