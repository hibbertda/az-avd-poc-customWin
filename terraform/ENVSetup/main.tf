##
# Prerequisites for deploying AVD with custom images
##

resource "azurerm_resource_group" "cg_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create Azure Compute Gallery for AVD images (SharedImageGallery)
resource "azurerm_shared_image_gallery" "avd_gallery" {
  name                = var.gallery_name
  resource_group_name = azurerm_resource_group.cg_rg.name
  location            = azurerm_resource_group.cg_rg.location
  description         = var.gallery_description
}

# Create Shared Image Definition in the Compute Gallery
resource "azurerm_shared_image" "avd_image" {
  name                = var.image_name
  resource_group_name = azurerm_resource_group.cg_rg.name
  location            = azurerm_resource_group.cg_rg.location
  gallery_name        = azurerm_shared_image_gallery.avd_gallery.name
  os_type             = var.image_os_type
  hyper_v_generation  = var.image_hyper_v_generation

  identifier {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
  }
}

# OUTPUT:
output "resource_group_name" {
  value = azurerm_resource_group.cg_rg.name
}
output "shared_image_gallery_name" {
  value = azurerm_shared_image_gallery.avd_gallery.name
}
output "shared_image_name" {
  value = azurerm_shared_image.avd_image.name
}
