terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.69.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resourceGroup-imageCreation" {
    name = "rg-${var.env["name"]}"
    location = var.env["region"]
}

module "network" {
  source = "./modules/network"

  env = var.env
  network = var.network
  rgName = azurerm_resource_group.resourceGroup-imageCreation.name
  
}

module "subnets" {
  source = "./modules/subnets"
  
  env = var.env
  network = var.network
  rgName = azurerm_resource_group.resourceGroup-imageCreation.name
  subnets = var.subnets
  vnet-name = module.network.vnet-name
  nsg-id = module.network.nsg-id
}

# module "imageGallery" {
#   source = "./modules/imageGallery"

#   env = var.env
#   rgName = azurerm_resource_group.resourceGroup-imageCreation.name
  
# }

module "keyVault" {
  source = "./modules/keyvault"
  
  env = var.env
  network = var.network
  rgName = azurerm_resource_group.resourceGroup-imageCreation.name  
  
}