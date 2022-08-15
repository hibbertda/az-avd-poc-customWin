# Windows 10/11 Custom Image

A custom OS image is created to include any customizations or applications required by users in Azure Virtual Desktop (AVD). This example uses the Chocolatley package manager to install a number of example tools, which is not required for AVD functionality. At the end of the image build process Sysprep is used to generalize the image in preperation for deployment.

## Azure Compute Gallery

The completed custom images are stored and managed using anAzure Compute Gallery. The Compute Gallery will hold the image, manage versions and replication to any other Azure regions where you intend to use the image.

- Global disk image replication
- Disk image versioning and grouping for easy management
- High-availability for disk image replicas (ZRS Storage)
- Share disk images across subscriptions / regions / Azure Active Directory tenants (via RBAC)

[Azure Compute Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/shared-image-galleries#:~:text=Shared%20Image%20Gallery%20is%20a%20service%20that%20helps,Versioning%20and%20grouping%20of%20images%20for%20easier%20management.)

The Packer templates are created to [automatically upload disk images to the Shared Image Gallery](https://www.packer.io/docs/builders/azure/arm#shared_image_gallery_destination).

## Prerequisites

- Resource group to deploy temporary build VM.
- RBAC permissions to deploy:
  - Deploy Virtual Machine
  - Deploy Virtual network
  - Publish image to Azure Compute Gallery
- Azure CLI **
- Packer executable **

<b>**</b> available in the Azure Cloud Shell

## Packer template

### Variables

<br />

#### build_vm

Defines configuration variables for the build VM. This includes the base OS image based from the Azure Marketplace.

```yaml
variable "build_vm" {
    description = "Build VM configuration"
    type = object({
        size_sku        = string
        os_disk_size    = number
        image_offer     = string
        image_publisher = string
        image_sku       = string
    })
    default = {
        size_sku            = "Standard_D2s_v3"
        os_disk_size        = 128
        #image_offer         = "windows-11"
        image_offer         = "Windows-10"
        image_publisher     = "microsoftwindowsdesktop"
        #image_sku           = "win11-21h2-avd"
        image_sku           = "21h1-evd-g2"
        resource_group      = "rg-win11-imageBuilder"
    }
}
```

|variable|Description|
|---|---|
|size_sku|Azure VM Sku for build vm. Only used for building the VM, doesn't have an impact on the future use of the VM. The selected SKU may impact the amount of time required for the build process to complete, based on the available resources (vCPU/RAM/etc).|
|os_disk_size|Managed disk size. Only for the build VM and doesn't impact future use of the VM. 128GB is a standard size for Azure VMs for simplicity.|
|image_offer|Azure Marketplace base OS image offer|
|image_publisher|Azure Marketplace base OS image publisher|
|image_sku|Azure Marketplace base OS image sku|
|resource_group|Resource Group where the build VM will be created. **Needs to be created before running the template, it will not be created automatically**|

<br />

#### Replication regions

Which Azure regions to replicate the image using the Compute gallery. **Note that when you add additional regions the build process will take longer because the image needs to complete replication to each specified region**

```yaml
variable "replication_regions" {
    description = "Select regions for replicating custom image"
    type = list(string)
    default = [
        "centralus"
    ]
}
```

|variable|Description|
|---|---|
|replication_regions|list of Azure regions to replicate the image in the compute gallery. You need to define at least a single regions. If you only add a single region make sure to select the region where you are planning to deploy virtual machines with the custom image.

#### Compute Gallery

Provide the name and resource group for the Azure Compute Gallery.

```yaml
variable "compute_gallery" {
    description = "Azure Compute Gallery"
    type = object({
        resource_group  = string
        gallery_name    = string
    })
    default = {
        resource_group = "rg-win11-imageBuilder"
        gallery_name = "avdimages"
    }
}
```

|variable|Description|
|---|---|
|resource_group|Resource Group name where the Azure Compute Gallery is deployed|
|gallery_name|Azure Compute gallery name|

#### Azure Compute Gallery

```yaml
    shared_image_gallery_destination {
        resource_group        = var.compute_gallery["resource_group"]
        gallery_name          = var.compute_gallery["gallery_name"]
        image_name            = "win10"
        image_version         = "{{isotime \"06\"}}.{{isotime \"01\"}}.{{isotime \"02030405\"}}"
        replication_regions   = var.replication_regions
    }
  }
```

|variable|Description|
|---|---|
|subscription| Subcription ID where the Shared Image Gallery is created |
|resource_group| Resource Group where the Shared Image Gallery is created |
|gallery_name| Shared Image Gallery Name|
|image_name| image name in the Shared Image Gallery. The image definition is not created automatically by the template. It must exists prior to running the Packer build, or the build process will fail.|
|image_version| version number is automatically generated based on the current data and time the template build is performed.|
|replication_regions| Azure regions to replicate the |

<br />

### Packer - Source

The source section defines the resources that are used for deploying a temporary build VM, connecting and running build process, and pushing to a Compute Gallery. The majority of these options are set using variables.

```yaml
source "azure-arm" "win11" {
    build_resource_group_name = var.build_vm["resource_group"]
    use_azure_cli_auth = true
    communicator = "winrm"
    
    image_offer = var.build_vm["image_offer"]
    image_publisher = var.build_vm["image_publisher"]
    image_sku = var.build_vm["image_sku"]
    os_type = "Windows"
    vm_size = var.build_vm["size_sku"]

    winrm_insecure                      = true
    winrm_timeout                       = "5m"
    winrm_use_ssl                       = true
    winrm_username                      = "packer"

    managed_image_name                  = "di-Win10"
    managed_image_resource_group_name   = "rg-win11-imageBuilder"

    shared_image_gallery_destination {
        resource_group        = var.compute_gallery["resource_group"]
        gallery_name          = var.compute_gallery["gallery_name"]
        image_name            = "win10"
        image_version         = "{{isotime \"06\"}}.{{isotime \"01\"}}.{{isotime \"02030405\"}}"
        replication_regions   = var.replication_regions
    }

}
```

### Packer - Build

Build defines the steps to configure the build VM. Provisioners are defined to perform different tasks on the build VM. The bulk of the work is done with PowerShell using the 'powershell' provisioner. 

```yaml
build {
    sources = ["source.azure-arm.win11"]

    provisioner "windows-update" {
    }

    provisioner "powershell" {
        script = "./scripts/install.ps1"
    }

    provisioner "powershell" {
        script = "./scripts/remove-choco.ps1"
    }

     provisioner "powershell" {
        script = "./scripts/sysprep.ps1"
    }   
}
```

|Script|Provisioner|Description|
|---|---|---|
|Windows Update|windows-update|Download and install the latest / available Windows Updates|
|install.ps1|PowerShell|Install example applications using the Chocolatey package manager for Windows|
|remove-choco.ps1|PowerShell|Uninstall Chocolatley|
|sysprep.ps1|PowerShell|Sysprep to generalize the VM|

<br />

## BUILD Custom Image

Open shell of choice and login to AzureCLI. For this example we will use the AzCLI logged in user to perform all tasks.

```bash
>az login
```

Use the **packer build** command from the image template directory to start the image build process.

```bash
>packer build .
```