# Windows 10 Data Analyst Image (Packer)

Builds a custom Windows 10 Enterprise multi-session image with data and admin tools pre-installed, then publishes it to an Azure Compute Gallery for use with Azure Virtual Desktop session hosts.

## Image Details

| Property | Value |
|----------|-------|
| **Base OS** | Windows 10 22H2 Enterprise multi-session (`win10-22h2-avd-g2`) |
| **Publisher** | `microsoftwindowsdesktop` |
| **Offer** | `Windows-10` |
| **Build VM SKU** | `Standard_D2s_v3` |
| **Cloud** | Supports Azure Public and Azure Government (`cloud_environment`) |

### Installed Applications

Installed via [Chocolatey](https://chocolatey.org/) package manager:

| Application | Chocolatey Package |
|-------------|-------------------|
| Visual Studio Code | `vscode` |
| Google Chrome | `googlechrome` |
| Git | `git.install` |
| PuTTY | `putty.install` |
| Azure PowerShell | `az.powershell` |
| Azure CLI | `azure-cli` |
| Azure Storage Explorer | `microsoftazurestorageexplorer` |
| AzCopy | `azcopy` |
| RSAT Tools | `rsat` |
| Python | `python` |
| VS Code Python Extension | `vscode-python` |

> Edit [scripts/install.ps1](scripts/install.ps1) to customize which applications are included.

## Prerequisites

- **Azure Compute Gallery** with an image definition created (matching the `image_name` in your variables)
- **Resource group** for the temporary build VM
- **Azure CLI** — authenticated (`az login`)
- **Packer** >= 1.9 with plugin:
  - `rgl/windows-update` 0.16.8

## Variables

### `build_vm`

| Variable | Type | Description |
|----------|------|-------------|
| `size_sku` | string | Azure VM SKU for the build VM |
| `os_disk_size` | number | Managed disk size in GB |
| `os_type` | string | OS type (`Windows`) |
| `image_offer` | string | Azure Marketplace image offer |
| `image_publisher` | string | Azure Marketplace image publisher |
| `image_sku` | string | Azure Marketplace image SKU |
| `resource_group` | string | Resource group for the build VM |
| `cloud_environment` | string | `Public` or `USGovernment` |

### `compute_gallery`

| Variable | Type | Description |
|----------|------|-------------|
| `image_name` | string | Destination image name in the Compute Gallery |
| `resource_group` | string | Compute Gallery resource group |
| `gallery_name` | string | Compute Gallery name |
| `replication_regions` | list(string) | Azure regions to replicate the image |

### `env`

| Variable | Type | Description |
|----------|------|-------------|
| `az_region` | string | Azure region for build resources |
| `allowed_ips` | list(string) | IP addresses allowed to connect to the build VM |

## Build Process

| Step | Provisioner | Script | Description |
|------|-------------|--------|-------------|
| 1 | `windows-update` | — | Download and install all available Windows Updates |
| 2 | `powershell` | `scripts/install.ps1` | Install applications via Chocolatey |
| 3 | `powershell` | `scripts/remove-choco.ps1` | Remove Chocolatey from the image |
| 4 | `file` | `app_images/` | Copy application images/assets to `C:\` |
| 5 | `powershell` | `scripts/sysprep.ps1` | Generalize the VM with Sysprep |

Image versions are automatically generated from the build timestamp: `YY.MM.DDHHmmss`.

## Usage

```bash
# Authenticate
az login

# Initialize Packer plugins
packer init .

# Build with variable overrides (e.g., Gov Cloud)
packer build -var-file="var.pkrvars.hcl" .
```

### Gov Cloud Example

The included [var.pkrvars.hcl](var.pkrvars.hcl) provides overrides for Azure Government:

```hcl
build_vm = {
  cloud_environment = "USGovernment"
  resource_group    = "rg-avd-images-usgovvirginia"
  # ...
}
```