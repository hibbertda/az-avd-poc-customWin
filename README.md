# Azure Virtual Desktop (AVD) - Template Deployment (POC)

Templates to automatically build out a full AVD environment with session hosts built with a customer Windows 10/11 image.

- Packer template to create custom Windows 10/11 base os image.
- Template deployment for AVD workspace, hostpools, and session hosts.

## Environment Configuration


### Requirements

- Active Azure Subscription
- Permissions to deploy Resource Groups and Azure resources
- **Active Directory Domain Services (AD DS)**: needed to join session host VMs and authenticate users. Can be traditional AD DS or Azure Active Directory Domain Services (AAD DS). The subnet for session host VMs requires network access to join the domain.

## Templates

## Prereqs

The Prereqs template will deploy resources that AVD will depend on.

||Description|
|---|---|
|avd-domain-user|AAD account for adding sessions host VMs to the ADD DS domain|
|Resource Group - Core | Core / Common AVD resources. Will be used across all AVD hostpools in the tenant|
|Resource Group - Images | Custom image resources|
|Key Vault| Storage for deployment and service secrets. All passwords generated during the deployment will be placed in the key vault|
|Network|Required network resouces include VNet and Subnets|
|Profile Storage|Azure Storage account for storing persistent user profiles (FSLogix)|
|Compute Gallery|Azure Compute Gallery for storage / managment of custom images used for AVD|

### variables

```yaml
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
```

|Variable|Type|Description|
|---|---|---|
|tags|list||
|location|string|Default Azure region. All resources will be created in this region|
|virtualNetwork|object|Virtual network to host session host VMs|
|subnets|list(object)|VNet subnets.|
|enable_bastion|bool|for future use|
|images|list(object)|OS image definitions in the Azure Compute Gallery|

### Post Deployment

These resources are broken out in part because there is the potential for the need for additional manual configuration before deploying the remaining AVD components.

#### AD DS Connectivity

The Virtual Network created in this step needs to be configured with a path (VNet Peering, VPN, etc) to access Active Directory Domain Services (AD DS) resources.

#### Custom OS Image

Publish a custom Windows 10/11 OS image to the Azure Compute Gallery. The following example uses Hashicorp Packer to create the image and transfer it to the Compute Gallery.

[PACKER Example Windows 10 custom image](./windows-data-image/)

## AVD Resources

The AVD Resources template will deploy all AVD resources and session host virtual machines.

### variables

```yaml
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
```

|variable|type|description|
|---|---|---|
|location|string|Default Azure region. All resources will be created in this region|
|tags|list||
|avd_config|list(object)|List of AVD configuration options. Each object in the list will result in a seperate set of AVD resources (hostpool/workspace/Application Group)|
|adds-join-username|string|AD DS admin user name (domain join)|
|adds-join-password|secure string|AD DS admin user password (domain join)
|session hosts|object|common options for all session hosts|
