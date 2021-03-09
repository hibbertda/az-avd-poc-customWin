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

The service principal was created from the Azure CLI command-line.

```bash
az ad sp create-for-rbac --name sp-WVDPilot-AzureDevOps-core-P-01
```
[Azure Docs: AzCLI Create Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli#create-a-service-principal)

## Templates

A series of templates are included to automate the deployment and configuration of WVD assets. Including automated process to built and maintain a managed Windows 10 (multi-user) OS image. 

## WVD Usecases

There are four use cases identified for targeting specific user requirements and needs for Windows Virtural Desktop (WVD).

|Usecase | Description
|---|---|
|General purpose| General purpose Windows 10 desktop. Includes standard Office apps and LOB applications. Configuration should match existing end-user desktop. |
|Developer| Developer workstation with approved developer tools |
|Administrator|Windows 10 with administrative tools and access. |

<hr>

### General Purpose

Standard user workstation to enable remote access to organization application and resources. Experience will mirror physical Windows 10 workstations with approved organizational settings. 

The General Purpose use case assumes:
- Standard user workstation
- Inlcudes organization line of business and productivity applications.
- Pooled Windows 10 multi-user workstations.
- Profile persistance enabled (FSLogix).

### Developer



![wvd high-level architecture](/static/wvd-developer-highlevel.png)

The developer use case assumes:

- Standard set of developer tools are installed.
- Users will have full or limited adminitrative rights to the workstation.
- No productivity tools (ie Office) will be installed.


### Administrator

TBD. Additional research and deliberation required before making a recommendation.
