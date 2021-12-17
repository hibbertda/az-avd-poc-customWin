
variable "env" {
  type = map
}

variable "network" {
  type = map
}

variable "rgName" {
    type = string
}

variable "subnets" {
    type = map
}

variable "vnet-name" {
    type = string
}

variable "nsg-id" {
    type = string
}

# Create subnets, including Azure Bastion /27
resource "azurerm_subnet" "subnets" {
    for_each                = var.subnets
    name                    = "sn-${each.key}"
    resource_group_name     = var.rgName
    virtual_network_name    = var.vnet-name

    address_prefixes    = [cidrsubnet(var.network["ipv4Network"], 11, each.value)]
}


resource "azurerm_subnet_network_security_group_association" "nsg-association" {
    for_each    = azurerm_subnet.subnets
    subnet_id                 = each.value.id
    network_security_group_id = var.nsg-id
}