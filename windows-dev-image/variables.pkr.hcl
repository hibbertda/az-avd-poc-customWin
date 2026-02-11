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
    resource_group  = string
    gallery_name    = string
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
    type = list(string)
    default = [
        "centralus"
    ]
}