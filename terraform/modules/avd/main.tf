
resource "azurerm_virtual_desktop_host_pool" "hostpool"{
	location            			= var.resourcegroup.location
	resource_group_name 			= var.resourcegroup.name

	name 											= "hp-${var.avd_config["name"]}-${var.random}"
	friendly_name 						= "hp-${var.avd_config["name"]}-${var.random}"
	description 							= var.avd_config["description"]
	type 											= var.avd_config["type"]
	maximum_sessions_allowed 	= var.avd_config["max_sessions"]
	load_balancer_type 				= var.avd_config["load_balancer_type"]
  custom_rdp_properties 			= "use multimon:i:1;screen mode id:i:1;smart sizing:i:1;dynamic resolution:i:1;audiomode:i:1;redirectclipboard:i:1;redirectsmartcards:i:1;redirectwebauthn:i:1"

	start_vm_on_connect 			= true
  tags                      =  var.tags
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = timeadd(timestamp(), "2h")
}

resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                	= "avdwksp-${var.avd_config["name"]}-${var.random}"
	location            	= var.resourcegroup.location
	resource_group_name 	= var.resourcegroup.name
  friendly_name 				= var.avd_config["friendly_name"]
  description   				= var.avd_config["description"]
  tags                  = var.tags
}

resource "azurerm_virtual_desktop_application_group" "desktopapp" {
  name                					= "avdag-${var.avd_config["name"]}-${var.random}-desktop"
	location            					= var.resourcegroup.location
	resource_group_name 					= var.resourcegroup.name

  type          								= "Desktop"
	default_desktop_display_name 	= "Desktop"
  host_pool_id  								= azurerm_virtual_desktop_host_pool.hostpool.id
  friendly_name 								= "TestAppGroup"
  description   								= "Acceptance Test: An application group"
  tags                          =  var.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspaceremoteapp" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.desktopapp.id
}

resource "azuread_group" "assignment_group" {
  display_name     = "avd-${var.avd_config["name"]}-${var.random}-users"
  owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true
}

data "azuread_client_config" "current" {}

data "azurerm_role_definition" "desktop_virtualization_user" {
  name = "Desktop Virtualization User"
}

resource "azuread_group_member" "avd-group" {	
  group_object_id  = azuread_group.assignment_group.id
  member_object_id = data.azuread_client_config.current.object_id
}

resource "azurerm_role_assignment" "avd_users_desktop_virtualization_user" {
  scope              = azurerm_virtual_desktop_application_group.desktopapp.id
  role_definition_id = data.azurerm_role_definition.desktop_virtualization_user.id
  principal_id       = azuread_group.assignment_group.id
}