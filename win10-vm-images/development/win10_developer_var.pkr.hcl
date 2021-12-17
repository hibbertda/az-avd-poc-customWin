variable "env" {
#    type = map
    default = {
        "build_rg"          = "rg-win10image"
        "build_region"      = "CentralUS"
        "az_subscription"   = ""
        "cloud_type"        = "Public"


    }
}
variable "vm" {
#    type = map
    default = {
        "image_offer"       = "Windows-10"
        "image_publisher"   = "MicrosoftWindowsDesktop"
        "image_sku"         = "19h2-evd"
        "os_disk_size"      = 128
        "os_type"           = "Windows"
        "size"              = "Standard_D2_v2"
    }
}

variable "network" {
#    type = map
    default = {
        "vnet_name"     = "vnet-win10image-01"
        "rg"            = "rg-win10image"
        "subnet"        = "sn-vm"
    }
}
