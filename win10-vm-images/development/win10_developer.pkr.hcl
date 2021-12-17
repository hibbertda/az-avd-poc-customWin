source "azure-arm" "win10Dev" {
    #subscription_id             = var.env["az_subscription"]
    cloud_environment_name      = var.env["cloud_type"]
    build_resource_group_name   = var.env["build_rg"]
    use_azure_cli_auth          = true

    private_virtual_network_with_public_ip = true

    communicator                = "winrm"
    winrm_insecure              = true
    winrm_timeout               = "5m"
    winrm_use_ssl               = true
    winrm_username              = "packer"

    # Azure Marketplace image definition
    # -- Base image will be sources from the Azure Marketplace
    image_offer                         = var.vm["image_offer"]
    image_publisher                     = var.vm["image_publisher"]
    image_sku                           = var.vm["image_sku"]
    os_disk_size_gb                     = var.vm["os_disk_size"]
    os_type                             = "Windows"
    vm_size                             = var.vm["size"]

    # Build Network
    virtual_network_name                = var.network["vnet_name"]
    virtual_network_resource_group_name = var.network["rg"]
    virtual_network_subnet_name         = var.network["subnet"]   

    managed_image_name                  = "image01"
    managed_image_resource_group_name   = var.env["build_rg"]
}

build {
    sources = [
        "source.azure-arm.win10Dev"
    ]

    # Run Windows Update and install available updates
    provisioner "powershell" {
        script  = "./build_scripts/winUpdate.ps1"
    }

    # Restard VM after Windows Updates are installed
    provisioner "windows-restart" {}

    provisioner "powershell" {
        script  = "./build_scripts/appInstall.ps1"
    }

    # Perform SysPrep (Required for use in Azure)
    provisioner "powershell" {
        script  = "./build_scripts/sysprep.ps1"
    }

}