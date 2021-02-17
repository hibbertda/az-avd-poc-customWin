# Windows Virtual Desktop - Testing Environment (POC)

Proof of concept for deploying Windows Virtual Desktop (WVD). The POC will include 

- Creation of Azure DevOps pipeline to automate the creation of custom Windows 10 disk images
- Template deployment for WVD workspace and hostpools
- Assign developer identities to developer host VMs.

*[note 11/9/2020]*

## Environment Configuration

### Azure DevOps Service Connection

An Azure Service Principal (sp) was created to create an Azure DevOps service connection for deployment.

|Name||
|---|---|
|sp-WVDPilot-AzureDevOps-core-P-01||

The SP was created from the Azure CLI command-line.

```bash
az ad sp create-for-rbac --name sp-WVDPilot-AzureDevOps-core-P-01
```
[Azure Docs: AzCLI Create Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli#create-a-service-principal)

## Templates


## WVD Usecases

Four use cases have been 

|Usecase | Description
|---|---|
|Developer| Developer workstation with approved developer tools |
|Administrator|Windows 10 with administrative tools and access. |
|General| General purpose Windows 10 desktop. Includes standard Office apps and LOB applications. Configuration should match existing end-user desktop. |

### Developer

![wvd high-level architecture](/static/wvd-developer-highlevel.png)

The developer use case assumes:

- Standard set of developer tools are installed.
- Users will have full or limited adminitrative rights to the workstation.
- No productivity tools (ie Office) will be installed.


### Administrator

### General
