resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-avd-${var.random}"
  location            = var.resourcegroup.location
  resource_group_name = var.resourcegroup.name
  address_space       = var.virtualnetwork["address_space"]
}

resource "azurerm_subnet" "subnets" {
    depends_on = [
      azurerm_virtual_network.vnet
    ]
	for_each = {
		for index, subnet in var.subnets:
		subnet.name => subnet
	}
  name                  = each.value.name  
  resource_group_name   = var.resourcegroup.name
  virtual_network_name  = azurerm_virtual_network.vnet.name
  address_prefixes      = each.value.address_prefix 

  private_link_service_network_policies_enabled = true
  private_endpoint_network_policies_enabled = true
}
# resource "azurerm_public_ip" "baspip" {
#   name                = "pip-bad-${var.random}"
#   location            = var.resourcegroup.location
#   resource_group_name = var.resourcegroup.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_bastion_host" "example" {
#   name                = "bastion"
#   location            = var.resourcegroup.location
#   resource_group_name = var.resourcegroup.name

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.subnets["AzureBastionSubnet"].id
#     public_ip_address_id = azurerm_public_ip.baspip.id
#   }
# }
/*
Configure VNET peering to AD DS / AAD DS subnet to enable
domain join for session host virtual machines.
*/
# resource "azurerm_virtual_network_peering" "peer-2-aadds" {
#   for_each                  = var.remote_vnet_peer
#   name                      = "${azurerm_virtual_network.vnet.name}-to-aadds"
#   resource_group_name       = var.resourcegroup.name
#   virtual_network_name      = azurerm_virtual_network.vnet.name
#   remote_virtual_network_id = each.value
# }

# resource "azurerm_virtual_network_peering" "aadds-2-peer" {
#   for_each                  = var.remote_vnet_peer
#   #provider                  = azurerm.identity
#   name                      = "aadds-to-${azurerm_virtual_network.vnet.name}"
#   resource_group_name       = "rg-coeart-identity-network"
#   virtual_network_name      = each.value
#   remote_virtual_network_id = azurerm_virtual_network.vnet.name
# }