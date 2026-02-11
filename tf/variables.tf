variable "location" {
  type        = string
  description = "Azure Region"
}

variable "tags" {
  type        = map(string)
  description = "Azure Resource tags"
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
      name           = optional(string, "vm")
      address_prefix = list(string)
    }
  ))
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

# Remove AD DS related variables since we're using pure Entra ID
# variable "adds-join-username" {
#   description = "ADDS Join username"  
#   type        = string
# }

# variable "adds-join-password" {
#   description = "ADDS Join password"
#   type        = string
#   sensitive   = true
# }

variable "sessionhosts" {
  description = "Session Host virtual machine options"
  type = object({
    size         = string
    local_admin  = optional(string, "shadmin")
    gallery_name = string
    gallery_rg   = string
    # Remove adds_domain_name since we're not using AD DS
    # adds_domain_name  = optional(string)
  })
}