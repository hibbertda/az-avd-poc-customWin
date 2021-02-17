# Azure Windows Virtual Desktop - Demo / POC Environment
## Requirements

### Terraform state storage

Terraform state is stored in an Azure Storage account. The identity running the template requires access to the storage account. 

[Backend Configuration](#Backend-Configuration) has details on the expected backend storage configuration.

### Azure KeyVault

The template assumes an Azure KeyVault will exist to store secrets required for deploying certain resource types. 

The KeyVault can either be created on its own (or use existing). The Secrets below need to be created, and the identity running the templated needs an [Access Policy](https://docs.microsoft.com/en-us/azure/key-vault/general/assign-access-policy-portal#:~:text=%20Assign%20an%20access%20policy%20%201%20In,the%20Principal%20selection%20pane.%20Enter%20the...%20More%20) to allow access to read the secrets.

The [InfraPrep](../infra-prep) template can be used to automate the deployment of the keyvault.

|Secret|Description|
|---|---|
|vm-admin-password| Virtual Machine local administrator account
|adds-join-username| Username with rights to add computers to the AD DS domain.
|adds-join-password| Password for domain join account

---

## Backend Configuration

Terraform state files are stored in an Azure storage account. The AzureRM backend configuration includes pointers to the storage account and container.

The identity used to run the templated needs to have **READ/WRITE** access to the storage account.

```yaml
terraform {
backend "azurerm" {
    resource_group_name     = "hbl-demo-env"
    storage_account_name    = "hblwvdterrstate"
    container_name          = "wvdstate"
    key                     = "wvdstate.tfstate"
    }
}
```

---

## Modules

### wvd_workspace

Creation of the Windows Virtual Desktop (WVD) workspace

### wvd_hostpool_developers

Creation of a WVD hostpool 

### wvd_session_host (in-progress)

Deploy WVD host virtual machines.

---

## Template Variables

### env

Variables describing general inforamtion for the deployment environment. These variables are used across the entire deployment.

|Variable|Description
|---|---|
|envName| Project or environment name (ex: wvddev)
|region| Prefered region for deployment. All resources will be deployed to this Azure region.
|keyvaultName| Name of Azure KeyVault that stores required secrets.
|keyvaultRG| Resource group name for Azure KeyVault that stores required secrets. 

```yaml
variable "env" {
    type = map
    default = {
        envName       = "wvddemo"
        region        = "centralus"
        keyvaultName  = "kv-wvddemo-centralus"
        keyvaultRG    = "hbl-wvddemo-centralus-management"
    }
}
```

### hostvm

The 'hostvm' variables descript configuration required for deploying WVD session host virtual machines.

|Variable|Descrpition
|---|---|
|vmSize| Azure VM Size sku for session host virtual machine
|publisher| Source vm image publisher
|offer| Source vm image offer
|sku| Source vm image offer sku
|osDiskSizeGB| OS disk size (in GB), will automatically be rounded up to the nearest managed disk size.
|adminUserName| Local administrator name. Password is sourced from Azure KeyVault.
|addsDomain| Active Directory (AD DS) domain name. The WVD host pool virtual machines will be added to the domain.
|vnetName| Virtual network name to associate virtual machine.
|vnetRG| Resource group name for target virtual network.
|subnetName| VNet Subnet name to associate virtual machine.

The example variables will deploy a standard Windows 10 multi-session virtual machine.

```yaml
# Configuration variables for session host VMs
variable "hostvm" {
    type    = map
    default = {
        # Azure VM Sku Size
        vmSize          = "Standard_D2s_v3"    
        # Image publisher         
        publisher       = "MicrosoftWindowsDesktop"    
        # Image offer 
        offer           = "Windows-10"          
        # Image offer sku        
        sku             = "19h2-evd"                    
        # VM OS disk size (GB)
        osDiskSizeGB    = 128
        # VM Local Administrator 
        adminUserName   = "wvdtestadmin"
        # AD DS domain name
        addsDomain      = "lab.thehibbs.net"
        # VNet Name
        vnetName        = "vnet-hbl-airs-demo-core-centralus"
        # VNet Resource Group name
        vnetRg          = "hbl-demo-network"
        # VNet Subnet name
        subnetName      = "sn-hbl-airs-demo-core-centralus-wvd"
    }
}
```