variable "env" {
  type = map
}

variable "rgName" {
  type = string
}

resource "azurerm_shared_image_gallery" "sig-win10" {
  name                = "AVD_Win10"
  resource_group_name = var.rgName
  location            = var.env["region"]
  description         = "Win10 AVD images"
}