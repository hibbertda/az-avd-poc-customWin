resource "random_string" "sarandom" {
  length = 8
  special = false
  lower = true
  upper = false
}

# Prereqs

module "avd_keyvault" {
	source              = "./modules/keyvault"
	resourcegroup       = azurerm_resource_group.avd-core
	random              = random_string.sarandom.result

	adds-join-username  = local.aad-domain-user
	adds-join-password  = random_password.password.result
}

module "network" {
  source 						= "./modules/network"
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

/*
AVD Resources
*/

resource "azurerm_resource_group" "avd" {
	for_each = {
			for index, config in var.avd_config:
			config.name => config
	}			
	name        = "rg-avd-${each.value.name}-resources-${random_string.sarandom.result}"
	location    =  var.location
  tags        =  var.tags
}

module "avd_workspace" {
	count 				= length(var.avd_config)	
	source 				= "./modules/avd"
	resourcegroup = azurerm_resource_group.avd[(var.avd_config[count.index]["name"])] #eww
	random 				= random_string.sarandom.result
	avd_config 		= var.avd_config[count.index]
  tags          =  var.tags
}

/*
## AVD Session Host ##
Build AVD Session Host VMs and add to the correct Host Pool. 
*/

resource "azurerm_resource_group" "avd-vm" {
	for_each = {
			for index, config in var.avd_config:
			config.name => config
	}				
	name        = "rg-avd-${each.value.name}-vms-${random_string.sarandom.result}"
	location    = var.location
  tags        = var.tags
}

# resource "azurerm_role_assignment" "avd-rg" {

# }



module "session_host_vm" {
	count 						  = length(var.avd_config)				
	source						  = "./modules/sessionHostVM"
	resourcegroup 		  = azurerm_resource_group.avd-vm[(var.avd_config[count.index]["name"])]
	sessionhosts 			  = var.sessionhosts
	host_pool_key 		  = module.avd_workspace[count.index].host_pool_key
	host_pool 				  = module.avd_workspace[count.index].host_pool
	avd_config 				  = var.avd_config[count.index]
  adds-join-username  = var.adds-join-username
  adds-join-password  = var.adds-join-password
  tags                = var.tags
}