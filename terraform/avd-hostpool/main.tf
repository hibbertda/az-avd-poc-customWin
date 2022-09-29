resource "random_string" "sarandom" {
  length = 8
  special = false
  lower = true
  upper = false
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
	source 				= "../modules/avd"
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



module "session_host_vm" {
	count 						  = length(var.avd_config)				
	source						  = "../modules/sessionHostVM"
	resourcegroup 		  = azurerm_resource_group.avd-vm[(var.avd_config[count.index]["name"])]
	sessionhosts 			  = var.sessionhosts
	host_pool_key 		  = module.avd_workspace[count.index].host_pool_key
	host_pool 				  = module.avd_workspace[count.index].host_pool
	avd_config 				  = var.avd_config[count.index]
  adds-join-username  = var.adds-join-username
  adds-join-password  = var.adds-join-password
  tags                = var.tags
}