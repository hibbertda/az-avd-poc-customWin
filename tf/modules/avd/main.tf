locals {
  required_role_definitions = [
    {
      name = "Azure Virtual Desktop Start VM on Connect"
      id   = "4cc7a616-3fdf-4014-9cf1-180636f7eee1"
    },
    {
      name = "Azure Virtual Desktop User"
      id   = "f5a3a1e9-4c8c-4e6f-83b1-0c996d5c4c6f"
    },
    {
      name = "Desktop Virtualization Power On Contributor"
      id   = "489581de-a3bd-480d-9518-53dea7416b33"
    },
    {
      name = "Virtual Machine user login"
      id   = "fb879df8-f326-4884-b1cf-06f3ad86be52"
    }
  ]
  role_id_prefix = "/providers/Microsoft.Authorization/roleDefinitions/"
}


resource "azurerm_virtual_desktop_host_pool" "hostpool"{
	location            			= var.resourcegroup.location
	resource_group_name 			= var.resourcegroup.name

	name 											= "hp-${var.avd_config["name"]}-${var.random}"
	friendly_name 						= "hp-${var.avd_config["name"]}-${var.random}"
	description 							= var.avd_config["description"]
	type 											= var.avd_config["type"]
	maximum_sessions_allowed 	= var.avd_config["max_sessions"]
	load_balancer_type 				= var.avd_config["load_balancer_type"]
  custom_rdp_properties 		= <<EOT
    use multimon:i:1;
    screen mode id:i:1;
    smart sizing:i:1;
    dynamic resolution:i:1;
    audiomode:i:1;
    redirectclipboard:i:1;
    redirectsmartcards:i:1;
    redirectwebauthn:i:1;
    targetisaadjoined:i:1;
    enablerdsaadauth:i:1
  EOT
	start_vm_on_connect 			= true
  tags                      =  var.tags
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = timeadd(timestamp(), "24h")
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

# Apply required Azure Roles


data "azuread_client_config" "current" {}

resource "azuread_group_member" "avd-user-group" {
  group_object_id  = azuread_group.assignment_group.object_id
  member_object_id = data.azuread_client_config.current.object_id
}

data "azurerm_role_definition" "desktop_virtualization_user" {
  name = "Desktop Virtualization User"
}

# data "azurerm_role_definition" "Azure_virtual_Desktop_User" {
#   name = "Azure Virtual Desktop User"
# }

data "azurerm_role_definition" "Azure_virtual_Desktop_Start_VM_on_Connect" {
  name = "Desktop Virtualization Power On Contributor"
}

data "azurerm_role_definition" "Virtual_Machine_user_login" {
  name = "Virtual Machine user login"
}

resource "azurerm_role_assignment" "avd_users_desktop_virtualization_user" {
  scope              = azurerm_virtual_desktop_application_group.desktopapp.id
  role_definition_id = data.azurerm_role_definition.desktop_virtualization_user.id
  principal_id       = azuread_group.assignment_group.object_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}

# # resource "azurerm_role_assignment" "avd_users_Azure_virtual_Desktop_User" {
# #   scope              = azurerm_virtual_desktop_application_group.desktopapp.id
# #   role_definition_id = data.azurerm_role_definition.Azure_virtual_Desktop_User.id
# #   principal_id       = azuread_group.assignment_group.id
# # }

resource "azurerm_role_assignment" "avd_users_Azure_virtual_Desktop_Start_VM_on_Connect" {
  scope              = azurerm_virtual_desktop_application_group.desktopapp.id
  role_definition_id = data.azurerm_role_definition.Azure_virtual_Desktop_Start_VM_on_Connect.id
  principal_id       = azuread_group.assignment_group.object_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}

resource "azurerm_role_assignment" "avd_users_Virtual_Machine_user_login" {
  scope              = azurerm_virtual_desktop_application_group.desktopapp.id
  role_definition_id = data.azurerm_role_definition.Virtual_Machine_user_login.id
  principal_id       = azuread_group.assignment_group.object_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}



# # resource "azurerm_role_assignment" "avd_users_desktop_virtualization_user" {
# #   scope              = azurerm_virtual_desktop_application_group.desktopapp.id
# #   role_definition_id = data.azurerm_role_definition.desktop_virtualization_user.id
# #   principal_id       = azuread_group.assignment_group.id
# # }

# # loop through local.avd_user_role_definitions and assign each role to the group
# # resource "azurerm_role_assignment" "avd_users" {
# #   for_each = toset(local.avd_user_role_definitions)

# #   scope              = azurerm_virtual_desktop_application_group.desktopapp.id
# #   role_definition_id = data.azurerm_role_definition.desktop_virtualization_user.id
# #   principal_id       = azuread_group.assignment_group.id
# # }

# AVD Scaling Plan for automatic VM shutdown/startup
resource "azurerm_virtual_desktop_scaling_plan" "scaling_plan" {
  name                = "scaling-plan-${var.avd_config["name"]}-${var.random}"
  location            = var.resourcegroup.location
  resource_group_name = var.resourcegroup.name
  friendly_name       = "Scaling Plan for ${var.avd_config["friendly_name"]}"
  description         = "Automatic scaling plan for ${var.avd_config["name"]} host pool"
  time_zone           = "Eastern Standard Time"
  tags                = var.tags

  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.hostpool.id
    scaling_plan_enabled = true
  }

  schedule {
    name                                 = "weekdays_schedule"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "07:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 20
    ramp_up_capacity_threshold_percent   = 60

    peak_start_time                      = "09:00"
    peak_load_balancing_algorithm        = var.avd_config["load_balancer_type"]
    
    ramp_down_start_time                 = "17:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 10
    ramp_down_capacity_threshold_percent = 90
    ramp_down_force_logoff_users         = true
    ramp_down_stop_hosts_when            = "ZeroSessions"
    ramp_down_wait_time_minutes          = 30
    ramp_down_notification_message       = "You will be logged off in 30 min. Make sure to save your work."

    off_peak_start_time                  = "19:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }

  schedule {
    name                                 = "weekend_schedule"
    days_of_week                         = ["Saturday", "Sunday"]
    ramp_up_start_time                   = "09:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 10
    ramp_up_capacity_threshold_percent   = 80

    peak_start_time                      = "10:00"
    peak_load_balancing_algorithm        = var.avd_config["load_balancer_type"]
    
    ramp_down_start_time                 = "16:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 0
    ramp_down_capacity_threshold_percent = 90
    ramp_down_force_logoff_users         = true
    ramp_down_stop_hosts_when            = "ZeroSessions"
    ramp_down_wait_time_minutes          = 30
    ramp_down_notification_message       = "You will be logged off in 30 min. Make sure to save your work."

    off_peak_start_time                  = "18:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }
}

# Get the Azure Virtual Desktop Service Principal
data "azuread_service_principal" "avd_service_principal" {
  display_name = "Azure Virtual Desktop"
}

# Role assignment for AVD service to access host pool for scaling
resource "azurerm_role_assignment" "avd_service_host_pool_access" {
  scope                = azurerm_virtual_desktop_host_pool.hostpool.id
  role_definition_name = "Desktop Virtualization Power On Off Contributor"
  principal_id         = data.azuread_service_principal.avd_service_principal.object_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}

# Role assignment for AVD service to manage VMs in the resource group
resource "azurerm_role_assignment" "avd_service_vm_access" {
  scope                = var.resourcegroup.id
  role_definition_name = "Desktop Virtualization Power On Off Contributor"
  principal_id         = data.azuread_service_principal.avd_service_principal.object_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}