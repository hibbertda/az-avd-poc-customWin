packer {
  required_plugins {
    windows-update = {
      version = "0.16.8"
      source = "github.com/rgl/windows-update"
    }
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

variable "location" {
    description = "Azure region for the build VM"
    type        = string
}

variable "cloud_environment" {
    description = "Azure cloud environment (Public or USGovernment)"
    type        = string
    default     = "Public"
}

variable "az_compute_gallery" {
  description = "Azure Compute Gallery options"
  type = object({
    resource_group = string
    gallery_name   = string
  })
}

variable "shared_image" {
    description = "Shared Image Definition to build in Compute Gallery"
    type = object({
        name    = string
        os_type = string
        identifier = object({
            publisher = string
            offer     = string
            sku       = string
        })
    })
}

variable "build_vm" {
    description = "Build VM configuration"
    type = object({
        size_sku        = string
        os_disk_size    = number
        image_offer     = string
        image_publisher = string
        image_sku       = string
    })
}

variable "replication_regions" {
    description = "Select regions for replicating custom image"
    type        = list(string)
    default     = ["centralus"]
}

locals {
  shared_image_version = formatdate("YY.MM.DDhhmm", timestamp())
}

source "azure-arm" "win11" {
  location               = var.location
  cloud_environment_name = var.cloud_environment
  use_azure_cli_auth     = true
  communicator           = "winrm"

  image_offer     = var.build_vm["image_offer"]
  image_publisher = var.build_vm["image_publisher"]
  image_sku       = var.build_vm["image_sku"]
  os_type         = var.shared_image["os_type"]
  vm_size         = var.build_vm["size_sku"]
  os_disk_size_gb = var.build_vm["os_disk_size"]

  winrm_insecure  = true
  winrm_timeout   = "5m"
  winrm_use_ssl   = true
  winrm_username  = "packer"

  managed_image_name                = "${var.shared_image["name"]}-${replace(local.shared_image_version, ".", "-")}"
  managed_image_resource_group_name = var.az_compute_gallery["resource_group"]

  async_resourcegroup_delete = true

  shared_image_gallery_destination {
    resource_group      = var.az_compute_gallery["resource_group"]
    gallery_name        = var.az_compute_gallery["gallery_name"]
    image_name          = var.shared_image["name"]
    image_version       = local.shared_image_version
    replication_regions = var.replication_regions
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

  # Remove Chocolatey
  provisioner "powershell" {
    script = "./scripts/remove-choco.ps1"
  }

  provisioner "file" {
    source      = "./app_images/"
    destination = "c:\\"
  }

  # Sysprep
  provisioner "powershell" {
    script = "./scripts/sysprep.ps1"
  }
}