# Count of VMs to create
variable "sessionHostCount" {
    type = number
    default = 2
}

variable "env" {
    type = map
    default = {
        envName       = "coreWVD"
        # Azure Region
        #   All resources will be deployed to this region
        region        = "EastUS2"
        # Keyvault location
        #   KeyVault is used to store credentials for VMs and to AD DS domain join.
        keyvaultName  = ""
        keyvaultRG    = ""
    }
}

variable "imageGallery" {
    type    = map
    default = {
        # Shared Image Gallery Name
        sig_name            = "imCoreSharedImagesCorePEastUS201"
        # Shared Image Gallery Resource Group
        sig_resourceGroup   = "rg-CoreManagedServices-Core-P-01"
        # Shared Image Name
        sig_imageName       = "si-Win10-Developer-dev-01"
    }
}

# Configuration variables for session host VMs
variable "hostvm" {
    type    = map
    default = {
        # Azure VM Sku Size
        vmSize              = "Standard_D2s_v3"         
        # VM OS disk size (GB)
        osDiskSizeGB        = 128
        # VM Local Administrator 
        adminUserName       = "wvdpilotadmin"
        # AD DS domain name
        addsDomain          = ""
        # AD DS OU Path
        ouPath              = ""
        # VNet Resource Group name
        vnetRg              = ""        
        # VNet Name
        vnetName            = ""
        # VNet Subnet name
        subnetName          = ""
    }
}

variable "wvd-hostpool-name" {
    type = string
    default = ""
}

variable "wvd-hostpool-regkey" {
    type = string
    default = ""
}

variable "wvd_dsc_url" {
    type = string
    default = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip"
}