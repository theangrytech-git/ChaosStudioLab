terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.55.0"
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

  backend "azurerm" {
      resource_group_name  = "rg-tfstate"
      storage_account_name = "saukstfazureenv01"
      container_name       = "cstfstate"
      key                  = "terraform.tfstate"
  }
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
  #subscription_id = "b055686f-a26e-43f3-971e-f03a89a7979f"
  subscription_id = "c11180f8-e30c-4236-a81c-47d2ff9451e7"
  tenant_id = "8f9b88a7-3f3e-4be3-aae4-2006d4c42306"
  #use_oidc = true #Seeing issues with Auth for Storage Account, so using OIDC for now
}

provider "random" {
  # No additional configuration required
}