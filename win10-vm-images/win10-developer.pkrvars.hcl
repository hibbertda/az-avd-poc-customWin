
# Network 
net_vnet_name       = "vnet-Core-P-eastus2-01"
net_RG_vnet_name    = "rg-CoreNetworkingServices-Core-P-01"
net_subnet_name     = "Snet-Core-App-P-EastUS2-01"

# Build VM 
vm_size           = "Standard_D2_v2"
vm_os_disk_size   = 128

# Shared Image Gallery
sig_name          = "imCoreSharedImagesCorePEastUS201"
sig_resourceGroup = "rg-CoreManagedServices-Core-P-01"
sig_imageVer      = 1