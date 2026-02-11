packer {
  required_plugins {
    windows-update = {
      version = "0.16.8"
      source = "github.com/rgl/windows-update"
    }
  }
}

variable "env" {
  description = "Common environment information"
  type = object({
    az_region   = string        # Azure region to deploy image creation resources
    allowed_ips = list(string)  # Allowed IPs to access to build VM
  })
}

variable "build_vm" {
  description = "Build VM configuration"
  type = object({
      size_sku          = string  # VM Sku for build VM
      os_disk_size      = number  # build VM managed disk size
      os_type           = string  # OS type (Windows | Linux)
      image_offer       = string  # Source image_offer (Azure Marketplace)
      image_publisher   = string  # Source image_publisher (Azure Marketplace)
      image_sku         = string  # Source image_sku (Azure Marketplace)
      resource_group    = string  # Resource group to deploy build resources
      cloud_environment = string  # Azure cloud environment (Public | Gov)
  })
}

variable "compute_gallery" {
  description = "Azure Compute Gallery"
  type = object({
      image_name          = string        # Destination image in compute gallery
      resource_group      = string        # Compute gallery resource group
      gallery_name        = string        # Compute gallery name
      replication_regions = list(string)  # Azure Regions to replicate image
  })
}

locals {
  winrm_timeout   = "5m"
  winrm_insecure  = true
  winrm_ssl       = true
}

source "azure-arm" "win11" {
  build_resource_group_name           = var.build_vm["resource_group"]
  use_azure_cli_auth                  = true
  cloud_environment_name              = var.build_vm.cloud_environment
  communicator                        = "winrm"
  
  image_offer                         = var.build_vm["image_offer"]
  image_publisher                     = var.build_vm["image_publisher"]
  image_sku                           = var.build_vm["image_sku"]
  os_type                             = var.build_vm.os_type
  vm_size                             = var.build_vm["size_sku"]

  winrm_insecure                      = local.winrm_insecure
  winrm_timeout                       = local.winrm_timeout
  winrm_use_ssl                       = local.winrm_ssl
  winrm_username                      = "packer"

  managed_image_name                  = var.compute_gallery.image_name
  managed_image_resource_group_name   = var.build_vm["resource_group"]

  allowed_inbound_ip_addresses        = var.env.allowed_ips
  async_resourcegroup_delete          = true
  shared_image_gallery_replica_count  = 3

  shared_image_gallery_destination {
      resource_group        = var.compute_gallery["resource_group"]
      gallery_name          = var.compute_gallery["gallery_name"]
      image_name            = var.compute_gallery.image_name
      image_version         = "{{isotime \"06\"}}.{{isotime \"01\"}}.{{isotime \"02030405\"}}"
      replication_regions   = var.compute_gallery.replication_regions
  }
}

build {
  sources = ["source.azure-arm.win11"]

  # Apply all applicable / available Windows Updates
  provisioner "windows-update" {}

  # Application installation
  provisioner "powershell" {
      script = "./scripts/install.ps1"
  }

  # Remove Chocolately 
  provisioner "powershell" {
      script = "./scripts/remove-choco.ps1"
  }

  provisioner "file" {
    source = "./app_images/"
    destination = "c:\\"
  }

  # Sysprep
  provisioner "powershell" {
      script = "./scripts/sysprep.ps1"
  }   
}