packer {
  required_plugins {
    windows-update = {
      version = "0.16.8"
      source = "github.com/rgl/windows-update"
    }
    azure = {
        source = "github.com/hashicorp/azure"
        version = "~> 2"
    }
  }
}

locals {
    shared_image_version = formatdate("YY.MM.DDhhmm", timestamp())
}

source "azure-arm" "win11" {
    #build_resource_group_name = var.az_compute_gallery["resource_group"]
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
    
    #virtual_network_name                    = var.build_vm["vnet_name"]
    #virtual_network_resource_group_name     = var.az_compute_gallery["resource_group"]
    #virtual_network_subnet_name             = "${var.build_vm["vnet_name"]}-subnet"

    winrm_insecure                      = true
    winrm_timeout                       = "5m"
    winrm_use_ssl                       = true
    winrm_username                      = "packer"

    managed_image_name                  = "${var.shared_image["name"]}-${replace(local.shared_image_version, ".", "-")}"
    managed_image_resource_group_name   = var.az_compute_gallery["resource_group"]

    shared_image_gallery_destination {
        resource_group        = var.az_compute_gallery["resource_group"]
        gallery_name          = var.az_compute_gallery["gallery_name"]
        image_name            = var.shared_image["name"]
        image_version         = local.shared_image_version
        replication_regions   = var.replication_regions
    }

}

build {
    sources = ["source.azure-arm.win11"]

    provisioner "windows-update" {
    }

    provisioner "powershell" {
        script = "./scripts/install.ps1"
    }

    # provisioner "powershell" {
    #     script = "./scripts/remove-choco.ps1"
    # }

     provisioner "powershell" {
        script = "./scripts/sysprep.ps1"
    }   
}