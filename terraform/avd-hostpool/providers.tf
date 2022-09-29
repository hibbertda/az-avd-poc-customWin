terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
    }
  }
  # backend "azurerm" {
  #   #key = "terraform.tfstate"    
  # }
}

provider "azurerm" {
  features {

  }
}

provider "azurerm" {
  alias = "identity"
  subscription_id = var.identity_sub
  features {
    log_analytics_workspace {
      permanently_delete_on_destroy = true
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }    
  }
}

provider "azuread" {
  
}

