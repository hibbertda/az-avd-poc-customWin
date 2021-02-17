resource "azurerm_virtual_desktop_host_pool" "hostpool"{
    location            = var.rgLocation
    resource_group_name = var.rgName

    name = "wvdhp-${var.env["envName"]}-${var.env["region"]}"
    friendly_name = "wvdhp-${var.env["envName"]}"
    description = "Windows 10 worksations for developers"
    type = "Personal"
    maximum_sessions_allowed = 5
    load_balancer_type = "DepthFirst"
    personal_desktop_assignment_type = "Direct"

    registration_info {
        expiration_date = timeadd(timestamp(), "${var.registrationKeyLifetime}h")
    }
}

resource "azurerm_virtual_desktop_application_group" "desktopapp" {
  name                = "wvdag-${var.env["envName"]}-${var.env["region"]}"
  location            = var.rgLocation
  resource_group_name = var.rgName

  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.hostpool.id
  friendly_name = "Developer"
  description   = "POC: Developer Desktop"
}

output "wvd-hostpool-name" {
     value = azurerm_virtual_desktop_host_pool.hostpool.name
}

output "wvd-hostpool-regkey" {
    value = azurerm_virtual_desktop_host_pool.hostpool.registration_info[0].token
}