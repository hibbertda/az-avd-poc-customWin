variable "az_subscription_id" {
  type = string
}

variable "az_client_id" {
  type = string
}

variable "az_client_secret" {
  type = string
}

variable "az_tenant_id" {
  type = string
}

variable "az_environment" {
  type = string
  default = "Public"
}

## Build VM Virtual Network ##
variable "net_vnet_name" {
  type = string
}

variable "net_RG_vnet_name" {
  type = string
}

variable "net_subnet_name" {
  type = string
}

## Build VM ##
variable "vm_size" {
  type = string
  default = "Standard_D2_v2"
}

variable "vm_os_disk_size" {
  type = number
  default = 128
}

# Shared Image Gallery
variable "sig_name" {
  type = string
}

variable "sig_resourceGroup" {
  type = string
}

variable "sig_imageVer" {
  type = number
}

source "azure-arm" "win10developer" {
  azure_tags = {}
  build_resource_group_name           = "rg-DiskImageCreation-core-P-01"
  client_id                           = var.az_client_id
  client_secret                       = var.az_client_secret
  cloud_environment_name              = var.az_environment
  subscription_id                     = var.az_subscription_id
  tenant_id                           = var.az_tenant_id

  communicator                        = "winrm"
  ## Windows 10 Multi-User WVD base image
  image_offer                         = "Windows-10"
  image_publisher                     = "MicrosoftWindowsDesktop"
  image_sku                           = "19h2-evd"
  os_disk_size_gb                     = var.vm_os_disk_size
  os_type                             = "Windows"
  vm_size                             = var.vm_size

  # Build VM virtual network
  virtual_network_name                = var.net_vnet_name
  virtual_network_resource_group_name = var.net_RG_vnet_name
  virtual_network_subnet_name         = var.net_subnet_name

  winrm_insecure                      = true
  winrm_timeout                       = "5m"
  winrm_use_ssl                       = true
  winrm_username                      = "packer"

  shared_image_gallery_destination {
    subscription          = var.az_subscription_id
    resource_group        = var.sig_resourceGroup
    gallery_name          = var.sig_name
    image_name            = "si-Win10-Developer-dev-01"
    image_version         = "{{isotime \"06\"}}.{{isotime \"01\"}}.{{isotime \"02030405\"}}"
    replication_regions   = ["EastUS2"]
  }

  shared_image_gallery_timeout = "1h30m"

  managed_image_name                  = "di-Win10-Developer-dev-01"
  managed_image_resource_group_name   = "rg-DiskImageCreation-core-P-01"


}


build {
  sources = ["source.azure-arm.win10developer"]

  provisioner "powershell" {
    script  = "./build.ps1"
  }
}
