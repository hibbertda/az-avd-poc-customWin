variable "az_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "location" {
  type        = string
  description = "Azure Region"
}

variable "tags" {
  type        = map(string)
  description = "Azure Resource tags"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "VNet address space CIDR blocks"
  default     = ["10.12.0.0/16"]
}

variable "subnet_name" {
  type        = string
  description = "Subnet name for session host VMs"
  default     = "vm"
}

variable "subnet_prefix" {
  type        = list(string)
  description = "Subnet address prefix CIDR blocks"
  default     = ["10.12.1.0/24"]
}

variable "avd_config" {
  description = "AVD configuration options"
  type = list(object(
    {
      name                 = string
      friendly_name        = string
      description          = optional(string, "AVD Hostpool")
      type                 = optional(string, "Pooled")
      max_sessions         = number
      load_balancer_type   = optional(string, "DepthFirst")
      reg_key_lifetime_hrs = optional(number, 1)
      vm_prefix            = string
      vnet_name            = string
      vnet_rg              = string
      subnet_name          = string
      host_count           = optional(number, 0)
      image_name           = string
      app_group_type       = optional(string, "Desktop") # "Desktop" or "RemoteApp"
    }
  ))
}

variable "session_host_size" {
  type        = string
  description = "VM size for AVD session hosts"
}

variable "local_admin" {
  type        = string
  description = "Local admin username on session hosts"
  default     = "shadmin"
}

variable "gallery_name" {
  type        = string
  description = "Azure Compute Gallery name"
}

variable "gallery_rg" {
  type        = string
  description = "Resource group containing the Compute Gallery"
}