variable "tags" {
  description = "List of resource tags"
  type = object
  default = {
    "owner"       = "Daniel Hibbert"
    "projectName" = "AVD"
  }
}
variable "location" {
  description = "Default Azure Region"
  type = string
}

variable "virtualNetwork" {
  description = "Virtual network configuration"
  default = {
    address_space = ["10.12.0.0/16"]
  }
}

variable "subnets" {
  description = "Subnets"
  type = list(object(
    {
      name = optional(string, vm)
      address_prefix = list
    }
  ))
}

variable "enable_bastion" {
  type = bool
  default = false
}

variable "images" {
  description = "Custom OS Image definitions for Azure Compute Gallery"
  type = list(object(
    {
      name = string
      publisher = string
      offer = string
      sky = optional(string, "default")
    }
  ))
}