# variable "network" {
#     description = "Network information for build VM"
#     type = list(object){
#         vnet_name       = string
#         vnet_rg_name    = string
#         subnet_name     = string
#     }
# }

packer {
  required_plugins {
    windows-update = {
      version = "0.14.1"
      source = "github.com/rgl/windows-update"
    }
  }
}


variable "build_vm" {
    description = "Build VM configuration"
    type = object({
        size_sku        = string
        os_disk_size    = number
        image_offer     = string
        image_publisher = string
        image_sku       = string
        resource_group  = string
    })
    default = {
        size_sku            = "Standard_D2s_v3"
        os_disk_size        = 128
        #image_offer         = "windows-11"
        image_offer         = "Windows-10"
        image_publisher     = "microsoftwindowsdesktop"
        #image_sku           = "win11-21h2-avd"
        image_sku           = "21h1-evd-g2",
        resource_group      = "rg-avd-images-centralus"
    }
}

variable "replication_regions" {
    description = "Select regions for replicating custom image"
    type = list(string)
    default = [
        "centralus"
    ]
}

variable "compute_gallery" {
    description = "Azure Compute Gallery"
    type = object({
        resource_group  = string
        gallery_name    = string
    })
    default = {
        resource_group  = "rg-avd-images-centralus"
        gallery_name    = "cgavdimagegallery"
    }
}

source "azure-arm" "win11" {
    build_resource_group_name = var.build_vm["resource_group"]
    use_azure_cli_auth = true
    communicator = "winrm"
    
    image_offer = var.build_vm["image_offer"]
    image_publisher = var.build_vm["image_publisher"]
    image_sku = var.build_vm["image_sku"]
    os_type = "Windows"
    vm_size = var.build_vm["size_sku"]

    winrm_insecure                      = true
    winrm_timeout                       = "5m"
    winrm_use_ssl                       = true
    winrm_username                      = "packer"

    managed_image_name                  = "Win10-data"
    managed_image_resource_group_name   = var.build_vm["resource_group"]

    shared_image_gallery_destination {
        resource_group        = var.compute_gallery["resource_group"]
        gallery_name          = var.compute_gallery["gallery_name"]
        image_name            = "win10-data"
        image_version         = "{{isotime \"06\"}}.{{isotime \"01\"}}.{{isotime \"02030405\"}}"
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

    provisioner "powershell" {
        script = "./scripts/remove-choco.ps1"
    }

     provisioner "powershell" {
        script = "./scripts/sysprep.ps1"
    }   
}