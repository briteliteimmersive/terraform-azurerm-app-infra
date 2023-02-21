provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = false
    }
  }
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.44.0"
    }
  }
}