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
        sig_name            = ""
        # Shared Image Gallery Resource Group
        sig_resourceGroup   = ""
        # Shared Image Name
        sig_imageName       = ""
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
        adminUserName       = ""
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
