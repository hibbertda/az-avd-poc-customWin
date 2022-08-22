resource "random_string" "sarandom" {
  length = 8
  special = false
  lower = true
  upper = false
}
/*
## AVD Core##

Core resources that are shared by all of the AVD host pools (etc). 
All of the session host VMs will be joined to the same VNet and Subnet.
*/
resource "azurerm_resource_group" "avd-core" {
	name        = "rg-avd-core-${random_string.sarandom.result}"
	location    =  var.location
}

module "avd_keyvault" {
	source = "./modules/keyvault"
	resourcegroup = azurerm_resource_group.avd-core
	random = random_string.sarandom.result

	adds-join-username  = var.adds-join-username
	adds-join-password  = var.adds-join-password
}

module "network" {
  source 						= "./modules/network"
	resourcegroup 		= azurerm_resource_group.avd-core
	random 						= random_string.sarandom.result
  virtualnetwork  	= var.virtualNetwork
  subnets         	= var.subnets
	remote_vnet_peer 	= var.remote_vnet_peer
	#identitySubID = var.identity_sub
}

resource "azurerm_storage_account" "profile-storage" {
  name                			= "saprofile${random_string.sarandom.result}"
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
}

module "avd_workspace" {
	count 				= length(var.avd_config)	
	source 				= "./modules/avd"
	resourcegroup = azurerm_resource_group.avd[(var.avd_config[count.index]["name"])] #eww
	random 				= random_string.sarandom.result
	avd_config 		= var.avd_config[count.index]
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
	location    =  var.location
}

module "session_host_vm" {
	count 						  = length(var.avd_config)				
	source						  = "./modules/sessionHostVM"
	resourcegroup 		  = azurerm_resource_group.avd-vm[(var.avd_config[count.index]["name"])]
	subnet 						  = module.network.subnets["vm"]
	sessionhosts 			  = var.sessionhosts
	host_pool_key 		  = module.avd_workspace[count.index].host_pool_key
	host_pool 				  = module.avd_workspace[count.index].host_pool
	avd_config 				  = var.avd_config[count.index]
  adds-join-username  = var.adds-join-username
  adds-join-password  = var.adds-join-password
}