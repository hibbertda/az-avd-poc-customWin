resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "wvdwks-${var.env["envName"]}-${var.env["region"]}"
  location            = var.rgLocation
  resource_group_name = var.rgName

  friendly_name = "wvdwks-${var.env["envName"]}"
  description   = "WVD workspace for demo and testing"
}