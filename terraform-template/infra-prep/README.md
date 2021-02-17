# WVD Demo Infrastructure Prep

Create Azure infrastructure to support the deployment of Windows Virtual Desktop (WVD). 

## Azure KeyVault

Azure Keyvault is used to store all of the secrets used during the deployment. Including. 
 
- Session Host local administrator credentials
- Account for AD DS domain join
- WVD host pool key for joining a WVD host pool

The template will create several secrets that need to be updated before moving on to the next step(s).

A default KeyVault access policy is created for the identity used to run the template. 

## Shared Image Gallery

An Azure Shared Image Gallery is used to manage lifecylce and distribution of managed disk images.