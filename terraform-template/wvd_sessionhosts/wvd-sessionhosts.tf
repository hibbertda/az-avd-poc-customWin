provider "azurerm" {
    features {}
}
# Backend config.
terraform {
backend "azurerm" {
    resource_group_name     = "rg-DEVOPS-core-p-01"
    storage_account_name    = "stvmdevoptfstateastus201"
    container_name          = "wvdpocstate"
    key                     = "wvdpochoststate.tfstate"
    }
}


##
# Data: VNet Subnet
## 
data "azurerm_subnet" "wvd-subnet" {
    name                    = var.hostvm["subnetName"]
    virtual_network_name    = var.hostvm["vnetName"]
    resource_group_name     = var.hostvm["vnetRg"]
}

##
# Data: Key Vault
## 
data "azurerm_key_vault" "wvd-kv" {
    name = var.env["keyvaultName"]
    resource_group_name = var.env["keyvaultRG"]
}
##
# Key Vault Secrets
##
# VM Local admin username
# data "azurerm_key_vault_secret" "hostvmadminusername" {
#     name            = "vm-adminusername"
#     key_vault_id    = data.azurerm_key_vault.wvd-kv.id
# }
# VM  Local admin password
data "azurerm_key_vault_secret" "hostvm-admin-password" {
    name            = "vm-admin-password"
    key_vault_id    = data.azurerm_key_vault.wvd-kv.id
}
# ADDS Domain Join username
data "azurerm_key_vault_secret" "domain-join-username" {
    name            = "adds-join-username"
    key_vault_id    = data.azurerm_key_vault.wvd-kv.id
}
# ADDS Domain Join password
data "azurerm_key_vault_secret" "domain-join-password" {
    name            = "adds-join-password"
    key_vault_id    = data.azurerm_key_vault.wvd-kv.id
}

##
# Shared Image
##
data "azurerm_shared_image" "wvd-win10dev" {
    name                    = var.imageGallery["sig_imageName"]
    gallery_name            = var.imageGallery["sig_name"]
    resource_group_name     = var.imageGallery["sig_resourceGroup"]
}

# Create Session Host Resource Gorup
resource "azurerm_resource_group" "wvd-hosts" {
    name        = "rg-${var.env["envName"]}-sessionhosts-core-P-01"
    location    =  var.env["region"]
    tags    = {
        "Application Name"          = "WVD Developer Session Hosts"
        "End Date of the Project"   = "2021 Sept 30"
        "Country Code"              = "0001"
        "Environment"               = "Prod"
        "Disaster Recovery"         = "NA"
        "Start Date of the Project" = "2020 Nov 1"
    }    
}

# Create VM Network Interface
resource "azurerm_network_interface" "wvd-host-nic" {
    name                = "nic-wvdh-${var.env["envName"]}"
    location            = azurerm_resource_group.wvd-hosts.location
    resource_group_name = azurerm_resource_group.wvd-hosts.name

    ip_configuration {
        name                                = "nic-wvdh-${var.env["envName"]}-config"
        subnet_id                           = data.azurerm_subnet.wvd-subnet.id
        private_ip_address_allocation       = "Dynamic"
    }    
}

# Create azure virtual machine
resource "azurerm_virtual_machine" "wvd-vm-host" {
    name                    = "vm-${var.env["envName"]}-${var.env["region"]}-win10"
    location                = azurerm_resource_group.wvd-hosts.location
    resource_group_name     = azurerm_resource_group.wvd-hosts.name
    network_interface_ids   = [azurerm_network_interface.wvd-host-nic.id]
    vm_size                 = var.hostvm["vmSize"]

    storage_image_reference {
        # Resource ID of the target Shared Image
        id = data.azurerm_shared_image.wvd-win10dev.id
    }

    storage_os_disk {
        name                = "vm-${var.env["envName"]}-${var.env["region"]}-win10-osDisk"
        caching             = "ReadWrite"
        create_option       = "FromImage"
        managed_disk_type   = "Standard_LRS"
        disk_size_gb        = var.hostvm["osDiskSizeGB"]
    }

    os_profile {
        computer_name   = "vm-${var.env["envName"]}"
        admin_username  = var.hostvm["adminUserName"]
        admin_password  = data.azurerm_key_vault_secret.hostvm-admin-password.value
    }

    os_profile_windows_config {
        provision_vm_agent  = true
    }
}

# Add Virtual Machine to AD DS Domain
resource "azurerm_virtual_machine_extension" "domainJoin" {
  name                       = "vm-${var.env["envName"]}-domainJoin"
  virtual_machine_id         = azurerm_virtual_machine.wvd-vm-host.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  #depends_on                 = ["azurerm_virtual_machine_extension.LogAnalytics"]

#   lifecycle {
#     ignore_changes = [
#       settings,
#       protected_settings,
#     ]
#   }

  settings = <<SETTINGS
    {
        "Name": "${var.hostvm["addsDomain"]}",
        "User": "${data.azurerm_key_vault_secret.domain-join-username.value}",
        "Restart": "true",
        "Options": "3"
    }
    SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
         "Password": "${data.azurerm_key_vault_secret.domain-join-password.value}"
    }
    PROTECTED_SETTINGS
}

# Add virtual machien to WVD Host Pool
resource "azurerm_virtual_machine_extension" "additional_session_host_dscextension" {
  name                       = "vm-${var.env["envName"]}-${var.env["region"]}-win10-wvd_dsc"
  virtual_machine_id         = azurerm_virtual_machine.wvd-vm-host.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.domainJoin]

  settings = <<SETTINGS
    {
    "modulesURL": ${var.wvd_dsc_url},
    "configurationFunction": "Configuration.ps1\\RegisterSessionHost",
     "properties": {
            "hostPoolName":"${var.wvd-hostpool-name}",
            "registrationInfoToken":"${var.wvd-hostpool-regkey}"
        }
    }
    SETTINGS

}