terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
  use_cli             = true
  use_msi             = false
  subscription_id     = var.az_subscription_id
}