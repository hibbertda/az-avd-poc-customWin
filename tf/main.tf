resource "random_string" "random_uid" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

# Generate password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

data "azuread_domains" "aad-tenant" {
  only_initial = true
}

# Remove AD DS domain user reference - not needed for pure Entra ID
# locals {
#   aad-domain-user = "avd-domain-join2@${data.azuread_domains.aad-tenant.domains.0.domain_name}"
# }

# Prereqs

resource "azurerm_resource_group" "avd-core" {
  name     = "rg-avd-core-${var.location}-${random_string.random_uid.result}"
  location = var.location
  #tags        = var.tags
  tags = merge(var.tags, {
    "random" = random_string.random_uid.result
  })
}

module "avd_keyvault" {
  source        = "./modules/keyvault"
  resourcegroup = azurerm_resource_group.avd-core
  random        = random_string.random_uid.result

  # Remove AD DS credentials since we're using pure Entra ID
  # adds-join-username  = local.aad-domain-user
  # adds-join-password  = random_password.password.result
}

module "network" {
  source         = "./modules/network"
  resourcegroup  = azurerm_resource_group.avd-core
  random         = random_string.random_uid.result
  virtualnetwork = var.virtualNetwork
  subnets        = var.subnets
}

# Storage account temporarily disabled
# resource "azurerm_storage_account" "profile-storage" {
#   name                     = "saprofile0${random_string.random_uid.result}"
#   resource_group_name      = azurerm_resource_group.avd-core.name
#   location                 = azurerm_resource_group.avd-core.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"

#   # Use Azure AD Kerberos for pure Entra ID authentication
#   azure_files_authentication {
#     directory_type = "AADKERB"
#   }

#   # Security improvements for Entra ID joined machines
#   allow_nested_items_to_be_public = false
#   shared_access_key_enabled       = false  # Disable key-based auth for AADKERB
  
#   # Additional security settings for AAD authentication
#   min_tls_version                   = "TLS1_2"
#   infrastructure_encryption_enabled = true
  
#   # Enable AAD authentication for blob and queue services
#   blob_properties {
#     cors_rule {
#       allowed_headers    = ["*"]
#       allowed_methods    = ["GET", "HEAD", "POST", "PUT"]
#       allowed_origins    = ["*"]
#       exposed_headers    = ["*"]
#       max_age_in_seconds = 3600
#     }
#   }
  
#   tags = var.tags
# }

# resource "azurerm_storage_share" "profile-share" {
#   name                 = "user-profiles"
#   storage_account_name = azurerm_storage_account.profile-storage.name
#   quota                = 500
#   access_tier          = "Hot"

#   lifecycle {
#     prevent_destroy = true
#   }
  
#   depends_on = [azurerm_storage_account.profile-storage]
# }

# RBAC assignments for AAD authentication to storage account (disabled)
# data "azurerm_client_config" "current" {}

# # Assign Storage File Data SMB Share Contributor to the current user/service principal
# resource "azurerm_role_assignment" "storage_file_contributor" {
#   scope                = azurerm_storage_account.profile-storage.id
#   role_definition_name = "Storage File Data SMB Share Contributor"
#   principal_id         = data.azurerm_client_config.current.object_id
# }

# # Assign Storage Account Contributor for management operations
# resource "azurerm_role_assignment" "storage_account_contributor" {
#   scope                = azurerm_storage_account.profile-storage.id
#   role_definition_name = "Storage Account Contributor"
#   principal_id         = data.azurerm_client_config.current.object_id
# }

# /*
# AVD Resources
# */

resource "azurerm_resource_group" "avd" {
  for_each = {
    for index, config in var.avd_config :
    config.name => config
  }
  name     = "rg-avd-${each.value.name}-resources-${random_string.random_uid.result}"
  location = var.location
  tags     = var.tags
}

module "avd_workspace" {
  for_each = { for config in var.avd_config : config.name => config }

  source        = "./modules/avd"
  resourcegroup = azurerm_resource_group.avd[each.key]
  random        = random_string.random_uid.result
  avd_config    = each.value
  tags          = var.tags
}

# /*
# ## AVD Session Host ##
# Build AVD Session Host VMs and add to the correct Host Pool. 
# */

resource "azurerm_resource_group" "avd-vm" {
  for_each = {
    for index, config in var.avd_config :
    config.name => config
  }
  name     = "rg-avd-${each.value.name}-vms-${random_string.random_uid.result}"
  location = var.location
  tags     = var.tags
}

# # resource "azurerm_role_assignment" "avd-rg" {

# # }




module "session_host_vm" {
  for_each = { for config in var.avd_config : config.name => config }

  source              = "./modules/aadjoined-sessionHostVM"
  resourcegroup       = azurerm_resource_group.avd-vm[each.key]
  core_resourcegroup  = azurerm_resource_group.avd-core
  core_virtualnetwork = module.network
  sessionhosts        = var.sessionhosts
  host_pool_key       = module.avd_workspace[each.key].host_pool_key
  host_pool           = module.avd_workspace[each.key].host_pool
  avd_config          = each.value
  # Remove AD DS related variables since we're using pure Entra ID
  # adds-join-username  = var.adds-join-username
  # adds-join-password  = var.adds-join-password
  tags = var.tags
}