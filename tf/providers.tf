terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.53"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
  }
  required_version = ">= 1.0"
  
  # backend "azurerm" {
  #   #key = "terraform.tfstate"    
  # }
}

provider "azurerm" {
  subscription_id = "43c29ed9-84ff-4951-aada-57b4a0438ac6"
  
  # Use Azure AD authentication (default behavior)
  # This will use Azure CLI, Managed Identity, or Azure AD Service Principal
  use_cli                         = true
  use_msi                         = false
  use_oidc                        = false
  
  # Enable AAD authentication for storage operations
  # storage_use_azuread = true  # Disabled for now
  
  
  features {
    # Enhanced security features for AAD authentication
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    
    key_vault {
      # AAD authentication for Key Vault operations
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# provider "azurerm" {
#   alias = "identity"
#   subscription_id = var.identity_sub
#   features {
#     log_analytics_workspace {
#       permanently_delete_on_destroy = true
#     }
#     key_vault {
#       purge_soft_delete_on_destroy = true
#     }    
#   }
# }

provider "azuread" {
  # Use Azure AD authentication (default behavior)
  # This will use Azure CLI, Managed Identity, or Azure AD Service Principal
  use_cli = true
  use_msi = false
  use_oidc = false
}

