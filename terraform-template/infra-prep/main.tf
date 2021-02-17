# Create KeyVault resource for WVD deployment
provider "azurerm" {
    features {}
}
terraform {
backend "azurerm" {
    resource_group_name     = "hbl-demo-env"
    storage_account_name    = "hblwvdterrstate"
    container_name          = "infrastate"
    key                     = "infrastate.tfstate"
}
}

resource "azurerm_resource_group" "wvd-demo" {
    name        = "hbl-${var.env["envName"]}-${var.env["region"]}-management"
    location    =  var.env["region"]
}

module "wvd_keyvault" {
    source = "./modules/keyvault"
    env = var.env
    rgName              = azurerm_resource_group.wvd-demo.name
    rgLocation          = azurerm_resource_group.wvd-demo.location
    adds-join-username  = var.adds-join-username
    adds-join-password  = var.adds-join-password
    vm-admin-password   = var.vm-admin-password
}