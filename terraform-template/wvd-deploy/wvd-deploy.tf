provider "azurerm" {
    features {}
}
# Backend config.
terraform {
backend "azurerm" {
    resource_group_name     = "rg-DEVOPS-core-p-01"
    storage_account_name    = "stvmdevoptfstateastus201"
    container_name          = "wvdpocstate"
    key                     = "wvdpocstate.tfstate"
    }
}

data "azurerm_client_config" "current" {}

## RESOUECE GROUPS ##

# Create wvd services resource group
# Updated to meet INL naming standards
resource "azurerm_resource_group" "wvd-services" {
    name        = "rg-${var.env["envName"]}-core-P-01"
    location    =  var.env["region"]
    tags    = {
        "Application Name"          = "WVD front-end"
        "End Date of the Project"   = "2021 Sept 30"
        "Country Code"              = "0001"
        "Sub Region"                = "WASH-DC"
        "Environment"               = "Prod"
        "Disaster Recovery"         = "NA"
        "Org Code"                  = "019360"
        "Start Date of the Project" = "2020 Nov 1"
    }
}

## MODULES ##

# Create WVD Workspace
module "wvd_workspace" {
    source      = "./modules/wvd_workspace"
    rgLocation  = azurerm_resource_group.wvd-services.location
    rgName      = azurerm_resource_group.wvd-services.name
    env         = var.env
}

# Create WVD host pool for developer hosts
module "wvd_hostpool_developers" {
    source      = "./modules/wvd_hostpool"
    rgLocation  = azurerm_resource_group.wvd-services.location
    rgName      = azurerm_resource_group.wvd-services.name
    env         = var.env
}

# Create WVD session hosts
# module "wvd_session_hosts" {
#     source              = "./modules/wvd_sessionhosts"
#     env                 = var.env    
#     sessionHostCount    = 2
#     hostvm              = var.hostvm
#     wvd-hostpool-name   = module.wvd_hostpool_developers.wvd-hostpool-name
#     wvd-hostpool-regkey = module.wvd_hostpool_developers.wvd-hostpool-regkey
#     imageGallery        = var.imageGallery        
# }