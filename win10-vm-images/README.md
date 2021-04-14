# Windows 10 Custom Image - Developer

Custom Windows 10 disk image for use with INL Windows Virtual Desktop proof of concept. This image is designed for use by Developers. Includes a set of general tools.


## Shared Image Gallery

Azure Shared Imgage Gallery (SIG) is used to host and manage disk images shared across the orginzation.

- Global disk image replication
- Disk image versioning and group for easy management
- High-availability for disk image replicas (ZRS Storage)
- Share disk images across subscriptions / regions / Azure Active Directory tenants (via RBAC)

[Azure Shared Image Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/shared-image-galleries#:~:text=Shared%20Image%20Gallery%20is%20a%20service%20that%20helps,Versioning%20and%20grouping%20of%20images%20for%20easier%20management.)

The Packer templates are created to [automatically upload disk images to the Shared Image Gallery](https://www.packer.io/docs/builders/azure/arm#shared_image_gallery_destination). 

```yaml
  shared_image_gallery_destination {
    subscription          = var.az_subscription_id
    resource_group        = var.sig_resourceGroup
    gallery_name          = var.sig_name
    image_name            = "si-Win10-Developer-dev-01"
    image_version         = "{{isotime \"06\"}}.{{isotime \"01\"}}.{{isotime \"02030405\"}}"
    replication_regions   = ["EastUS", "CentralUS"]
  }
```

|variable|Description|
|---|---|---|
|subscription| Subcription ID where the Shared Image Gallery is created |
|resource_group| Resource Group where the Shared Image Gallery is created |
|gallery_name| Shared Image Gallery Name|
|image_name| image name in the Shared Image Gallery. The image definition is not created automatically by the template. It must exists prior to running the Packer build, or the build process will fail.|
|image_version| version number is automatically generated based on the current data and time the template build is performed.|
|replication_regions| Azure regions to replicate the |
