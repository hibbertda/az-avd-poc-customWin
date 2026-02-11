# Generate password
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

data "azurerm_subnet" "vm_subnet" {
  name                  = var.avd_config["subnet_name"]
  virtual_network_name  = var.avd_config["vnet_name"]
  resource_group_name   = var.avd_config["vnet_rg"]
}

data "azurerm_shared_image_version" "avdsh-image" {
	name                = "latest"
	image_name          = var.avd_config["image_name"]
	gallery_name        = var.sessionhosts["gallery_name"]
	resource_group_name = var.sessionhosts["gallery_rg"]
}

locals {
	avd_vm_prefix = "avdsh"
	vm_name       = "${local.avd_vm_prefix}-${var.avd_config["vm_prefix"]}"
}

resource "azurerm_network_interface" "avdsh-nic" {
	#count               = var.sessionhosts["count"]
  count               = var.avd_config["host_count"]
  name                = "${local.vm_name}-${count.index}nic-01"
  resource_group_name = var.resourcegroup.name
  location 						= var.resourcegroup.location
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "avdsh-vm" {
	count               = var.avd_config["host_count"]
  name                = "${local.vm_name}-${count.index}"
  resource_group_name = var.resourcegroup.name
  location 						= var.resourcegroup.location
  size                = var.sessionhosts["size"]
  admin_username      = var.sessionhosts["local_admin"]
  admin_password      = random_password.password.result
  tags                = var.tags
  
	network_interface_ids = [
    azurerm_network_interface.avdsh-nic[count.index].id
  ]

	license_type = "Windows_Client"
	boot_diagnostics {}

	source_image_id = data.azurerm_shared_image_version.avdsh-image.id

	os_disk {
		caching = "ReadWrite"
		storage_account_type = "Standard_LRS"
	}
}

resource "azurerm_virtual_machine_extension" "domain_join" {
	count 										 = var.avd_config["host_count"]
  name                       = "${local.vm_name}${count.index}-DomainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.avdsh-vm[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  settings = <<SETTINGS
    {
      "Name": "${var.sessionhosts["adds_domain_name"]}",
      "User": "${var.adds-join-username}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.adds-join-password}"
    }
PROTECTED_SETTINGS

  lifecycle {
    # create_before_destroy = true
    ignore_changes = [settings, protected_settings]
  }
}

resource "azurerm_virtual_machine_extension" "rdagent_install" {
	count                      = var.avd_config["host_count"]
  name                       = "${local.vm_name}${count.index}-RDAgentInstall"
  virtual_machine_id         = azurerm_windows_virtual_machine.avdsh-vm[count.index].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  tags                       = var.tags

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_3-10-2021.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${var.host_pool.name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${var.host_pool_key.token}"
    }
  }
PROTECTED_SETTINGS

  lifecycle {
    # create_before_destroy = true
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
  ]
}