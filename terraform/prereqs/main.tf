/*
## AVD Core##

Core resources that are shared by all of the AVD host pools (etc). 
All of the session host VMs will be joined to the same VNet and Subnet.
*/

# Generate password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_string" "random_uid" {
  length = 8
  special = false
  lower = true
  upper = false
}

data "azuread_domains" "aad-tenant" {
  only_initial = true
}

locals {
  aad-domain-user = "avd-domain-join2@${data.azuread_domains.aad-tenant.domains.0.domain_name}"
}

resource "azuread_user" "avd-domain-user" {
  user_principal_name = local.aad-domain-user
  display_name        = "AVD AD DS Domain Join Account"
  password            = random_password.password.result
}

resource "azurerm_resource_group" "avd-core" {
	name        = "rg-avd-core-${var.location}-${random_string.random_uid.result}"
	location    = var.location
  #tags        = var.tags
  tags = merge(var.tags, {
    "random" = random_string.random_uid.result
  })
}

# resource "azurerm_resource_group" "avd-images" {
# 	name        = "rg-avd-images-${var.location}"
# 	location    = var.location
#   tags        = var.tags
# }


module "avd_keyvault" {
	source              = "../modules/keyvault"
	resourcegroup       = azurerm_resource_group.avd-core
	random              = random_string.sarandom.result

	adds-join-username  = local.aad-domain-user
	adds-join-password  = random_password.password.result
}

module "network" {
  source 						= "../modules/network"
	resourcegroup 		= azurerm_resource_group.avd-core
	random 						= random_string.sarandom.result
  virtualnetwork  	= var.virtualNetwork
  subnets         	= var.subnets
}

resource "azurerm_storage_account" "profile-storage" {
  name                			= "saprofile0${random_string.sarandom.result}"
  resource_group_name 			= azurerm_resource_group.avd-core.name
  location                  = azurerm_resource_group.avd-core.location
  account_tier             	= "Standard"
  account_replication_type 	= "LRS"

	azure_files_authentication {
		directory_type = "AADDS"
	}
}

resource "azurerm_storage_share" "profile-share" {
  name                 = "user-profiles"
  storage_account_name = azurerm_storage_account.profile-storage.name
  quota                = 500
}

# resource "azurerm_shared_image_gallery" "avd-compute-gallery" {
#   name                = "cgavdimagegallery"
#   resource_group_name = azurerm_resource_group.avd-images.name
#   location            = azurerm_resource_group.avd-images.location
#   description         = "AVD Custom Windows Images"
# }

# resource "azurerm_shared_image" "windows-image" {
# 	for_each = {
# 		for index, image in var.images:
# 		image.name => image
# 	}
#   name                = each.value.name
#   gallery_name        = azurerm_shared_image_gallery.avd-compute-gallery.name
#   resource_group_name = azurerm_resource_group.avd-images.name
#   location            = azurerm_resource_group.avd-images.location
#   os_type             = "Windows"
#   hyper_v_generation  = "V2"

#   identifier {
#     publisher = each.value.publisher
#     offer     = each.value.offer
#     sku       = each.value.sku
#   }
# }