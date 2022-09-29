variable "location" {
  type = string
  default = "centralus"
}

variable "avd_config" {
  default = [
    {
			name = "datascience"
			description = "Windows workstations for data scientists"
			type = "Pooled",
			max_sessions = 5,
			load_balancer_type = "DepthFirst",
			reg_key_lifetime_hrs = 12
      vm_prefix = "ds"
		},
    # {
		# 	name = "demo"
		# 	description = "AVD Demo"
		# 	type = "Pooled",
		# 	max_sessions = 5,
		# 	load_balancer_type = "DepthFirst",
		# 	reg_key_lifetime_hrs = 12
    #   vm_prefix = "dm"
		# }    
  ]
}

variable "adds-join-username" {
    type = string
    default = "domain-join"
}

variable "adds-join-password" {
    type = string
    default = "P@ssword1"
}

variable "virtualNetwork" {
  description = "Virtual network configuration"
  default = {
    address_space = ["10.12.0.0/16"]
  }
}

variable "subnets" {
  description = "Subnets"
  default = [
    {
        name = "vm"
        address_prefix = ["10.12.3.0/24"]
    },
    {
        name = "AzureBastionSubnet"
        address_prefix = ["10.12.4.0/26"]
    }
  ]
}

variable "remote_vnet_peer" {
	type = set(string)	
	description = "remote VNETs to setup peering"
	default = [
		""
}

# variable "remote_dns_servers" {
# 	description = "Remote DNS servers for AD DS. Will be set on the VNET after peering"

# }

variable "identity_sub" {
  type = string
  default = "844ec848-530f-48cb-8e07-2f5e83b2e346"
}

variable "sessionhosts" {
  description = "Session Host virtual machine options"
  type = object({
    size          = string
    local_admin   = string
    count         = number
    gallery_name  = string
    gallery_rg    = string
    image_name    = string
    adds_domain_name = string
  })
  default = {
    size          = "Standard_D2s_v3"
    local_admin   = "shadmin"
    count         = 1
    gallery_name  = "avdimages"
    gallery_rg    = "rg-win11-imageBuilder"
    image_name    = "Win10"
    adds_domain_name = "artmsf.com"
  }
}

variable "enable_bastion" {
  type = bool
  default = false
}
