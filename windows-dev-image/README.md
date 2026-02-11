# Windows 11 Developer Image (Packer)

Builds a custom Windows 11 Enterprise image with developer tools pre-installed, then publishes it to an Azure Compute Gallery for use with Azure Virtual Desktop session hosts.

## Image Details

| Property | Value |
|----------|-------|
| **Base OS** | Windows 11 24H2 Enterprise (`win11-24h2-ent`) |
| **Publisher** | `microsoftwindowsdesktop` |
| **Offer** | `windows-11` |
| **Build VM SKU** | `Standard_D2s_v3` |

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
| Power BI Desktop | `powerbi` |
| Python | `python` |
| VS Code Python Extension | `vscode-python` |

> Edit [scripts/install.ps1](scripts/install.ps1) to customize which applications are included in the image.

## Prerequisites

- **Azure Compute Gallery** with an image definition matching `win_dev` (or update the `image_name` in the template)
- **Resource group** for the temporary build VM
- **Virtual network** with a `vm` subnet in the same resource group
- **Azure CLI** — authenticated (`az login`)
- **Packer** >= 1.9 with plugins:
  - `hashicorp/azure` ~> 2
  - `rgl/windows-update` 0.16.8

## Variables

### `build_vm`

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `size_sku` | string | `Standard_D2s_v3` | Azure VM SKU for the build VM |
| `os_disk_size` | number | `128` | Managed disk size in GB |
| `image_offer` | string | `windows-11` | Azure Marketplace image offer |
| `image_publisher` | string | `microsoftwindowsdesktop` | Azure Marketplace image publisher |
| `image_sku` | string | `win11-24h2-ent` | Azure Marketplace image SKU |
| `resource_group` | string | `custom_win_images` | Resource group for the build VM |
| `vnet_name` | string | `vnet-avd-build` | Virtual network for the build VM |

### `replication_regions`

List of Azure regions to replicate the image in the Compute Gallery. You must define at least one region — use the region where you plan to deploy session hosts.

```hcl
variable "replication_regions" {
    type    = list(string)
    default = ["centralus"]
}
```

### `compute_gallery`

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resource_group` | string | `custom_win_images` | Compute Gallery resource group |
| `gallery_name` | string | `avd_demo_images` | Compute Gallery name |

## Build Process

The Packer build runs these steps in order:

| Step | Provisioner | Script | Description |
|------|-------------|--------|-------------|
| 1 | `windows-update` | — | Download and install all available Windows Updates |
| 2 | `powershell` | `scripts/install.ps1` | Install applications via Chocolatey |
| 3 | `powershell` | `scripts/sysprep.ps1` | Generalize the VM with Sysprep |

> **Note:** The `remove-choco.ps1` provisioner is commented out by default. Uncomment it to remove Chocolatey from the final image for a cleaner production build.

Image versions are automatically generated from the build timestamp: `YY.MM.DDHHmmss`.

## Usage

```bash
# Authenticate
az login

# Initialize Packer plugins
packer init .

# Validate the template
packer validate .

# Build the image
packer build .
```

To override defaults, create a `.pkrvars.hcl` file:

```bash
packer build -var-file="custom.pkrvars.hcl" .
```