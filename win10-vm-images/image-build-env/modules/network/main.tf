variable "env" {
  type = map
}

variable "network" {
  type = map
}

variable "rgName" {
    type = string
}

resource "azurerm_virtual_network" "vnet" {
    name                = "vnet-${var.env["name"]}-01"
    location            = var.env["region"]
    resource_group_name = var.rgName
    address_space       = [var.network["ipv4Network"]]

}

resource "azurerm_network_security_group" "nsg" {
    name                    = "nsg-${var.env["name"]}"
    location                = var.env["region"]
    resource_group_name     = var.rgName
}

resource "azurerm_network_security_rule" "allow-rdp" {
  name                        = "AllowRDP"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.network["allowRemoteAccess"]
  destination_address_prefix  = "*"
  resource_group_name         = var.rgName
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow-winrm" {
  name                        = "AllowWinRM"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5985-5986"
  source_address_prefix       = var.network["allowRemoteAccess"]
  destination_address_prefix  = "*"
  resource_group_name         = var.rgName
  network_security_group_name = azurerm_network_security_group.nsg.name
}



output "vnet-id" {
    value = azurerm_virtual_network.vnet.id
}

output "vnet-name" {
    value = azurerm_virtual_network.vnet.name
}

output "nsg-id" {
    value = azurerm_network_security_group.nsg.id
}