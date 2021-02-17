# Env variables
variable "env" {
    type = map
}

# Count of VMs to create
variable "sessionHostCount" {
    type = number
    default = 2
}

# Virtual Machine Configuration
variable "hostvm" {
    type = map
}

variable "wvd-hostpool-name" {
    type = string
}

variable "wvd-hostpool-regkey" {
    type = string
}

# Shared Image Gallery information
variable "imageGallery" {
    type    = map
}

## Shouldnt need this
# variable "base_url" {
#     type = string
#     default = "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates"
# }

variable "wvd_dsc_url" {
    type = string
    default = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration.zip"
}