data "azurerm_subnet" "vm_subnet" {
  name                  = "vm"
  virtual_network_name  = var.core_virtualnetwork.vnet.name
  resource_group_name   = var.core_resourcegroup.name
}

data "azurerm_shared_image_version" "avdsh-image" {
	name                = "latest"
	image_name          = var.avd_config["image_name"]
	gallery_name        = var.sessionhosts["gallery_name"]
	resource_group_name = var.sessionhosts["gallery_rg"]
}