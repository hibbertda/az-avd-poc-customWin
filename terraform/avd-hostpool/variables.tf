variable "location" {
  type        = string
  description = "Azure Region"
}

variable "tags" {
  type        = map(string)
  description = "Azure Resource tags"
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
    }
  ))
}

variable "adds-join-username" {
    type        = string
    description = "ADDS Join username"
}

variable "adds-join-password" {
    type        = string
    description = "ADDS Join password"
    sensitive   = true
}

variable "sessionhosts" {
  description = "Session Host virtual machine options"
  type = object({
    size              = string
    local_admin       = optional(string, "shadmin")
    gallery_name      = string
    gallery_rg        = string
    adds_domain_name  = string
  })
}