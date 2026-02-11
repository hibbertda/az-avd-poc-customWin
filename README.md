# Azure Virtual Desktop (AVD) — Entra ID Joined

End-to-end templates for deploying an Azure Virtual Desktop environment with **Microsoft Entra ID joined** session hosts built from custom Windows images.

| Component | Tool | Purpose |
|-----------|------|---------|
| Custom OS Images | [HashiCorp Packer](https://www.packer.io/) | Build Windows 10/11 images with pre-installed applications |
| AVD Infrastructure | [Terraform](https://www.terraform.io/) (AzureRM 4.x) | Deploy host pools, workspaces, session hosts, networking |

## Repository Structure

```
├── tf/                          # Terraform — AVD infrastructure (Entra ID joined)
│   ├── main.tf                  # Root module: resource groups, modules
│   ├── variables.tf             # Input variables
│   ├── providers.tf             # Provider configuration (AzureRM 4.x, AzureAD 2.x)
│   ├── ds.tfvars                # Example variable values
│   └── modules/
│       ├── avd/                 # Host pool, workspace, app group, scaling plan
│       ├── aadjoined-sessionHostVM/  # Entra ID joined session host VMs
│       ├── network/             # VNet, subnets
│       ├── keyvault/            # Key Vault for secrets
│       └── sessionHostVM/       # (Legacy) AD DS joined session hosts
│
├── windows-dev-image/           # Packer — Windows 11 developer image
│   ├── windows-dev-image.pkr.hcl
│   └── scripts/
│       ├── install.ps1          # Chocolatey app installs (VS Code, Git, Azure CLI, etc.)
│       ├── remove-choco.ps1     # Chocolatey cleanup
│       └── sysprep.ps1          # Generalize image
│
├── windows-data-image/          # Packer — Windows 10/11 data analyst image
│   ├── windows-image.pkr.hcl
│   ├── var.pkrvars.hcl          # Variable overrides (Gov Cloud example)
│   └── scripts/
│       ├── install.ps1          # Chocolatey app installs (RSAT, Python, Power BI, etc.)
│       ├── remove-choco.ps1     # Chocolatey cleanup
│       └── sysprep.ps1          # Generalize image
│
└── terraform/                   # (Legacy) AD DS joined deployment — archived
```

> **Note:** The `terraform/` directory contains the original AD DS domain-joined deployment and is no longer actively maintained. Use `tf/` for Entra ID joined deployments.

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **Azure Subscription** | Active subscription with permissions to create resource groups, VMs, networking, and AVD resources |
| **Microsoft Entra ID** | Tenant with users/groups for AVD assignment |
| **Azure CLI** | v2.50+ — [Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| **Terraform** | v1.0+ — [Install](https://developer.hashicorp.com/terraform/install) |
| **Packer** | v1.9+ — [Install](https://developer.hashicorp.com/packer/install) |
| **Azure Compute Gallery** | Image definitions must exist before running Packer builds |

## Quick Start

### 1. Build a Custom Image

```bash
# Authenticate to Azure
az login

# Build the developer image
cd windows-dev-image
packer init .
packer build .

# Or build the data analyst image (with Gov Cloud overrides)
cd windows-data-image
packer init .
packer build -var-file="var.pkrvars.hcl" .
```

### 2. Deploy AVD Infrastructure

```bash
cd tf

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="ds.tfvars"

# Deploy
terraform apply -var-file="ds.tfvars"
```

## Architecture

### Identity & Authentication

This deployment uses **Microsoft Entra ID join** (no AD DS dependency):

- Session host VMs are joined to Entra ID via the `AADLoginForWindows` VM extension
- Users authenticate with Entra ID credentials
- RDP properties include `targetisaadjoined:i:1` and `enablerdsaadauth:i:1`
- No domain controllers, VPN tunnels, or AD DS connectivity required

### Custom Images (Packer)

Both image templates follow the same workflow:

1. **Provision** a temporary build VM from an Azure Marketplace image
2. **Windows Update** — apply all available patches
3. **Install applications** — via Chocolatey package manager
4. **Cleanup** — remove Chocolatey (optional)
5. **Sysprep** — generalize the image
6. **Publish** — upload to Azure Compute Gallery with automatic versioning

| Image | Base OS | Key Applications |
|-------|---------|-----------------|
| **Dev Image** | Windows 11 24H2 Enterprise | VS Code, Git, Azure CLI, Az PowerShell, Python, Storage Explorer, PuTTY |
| **Data Image** | Windows 10 22H2 AVD multi-session | VS Code, Git, Azure CLI, Az PowerShell, Python, RSAT |

### AVD Infrastructure (Terraform)

The Terraform deployment creates:

| Resource | Description |
|----------|-------------|
| **Resource Groups** | Separate RGs for core resources, AVD resources, and VMs |
| **Virtual Network** | VNet with VM and Bastion subnets |
| **Key Vault** | Stores generated passwords and secrets |
| **Host Pools** | Personal and/or Pooled host pools (defined in `avd_config`) |
| **Workspaces** | AVD workspaces per host pool |
| **Application Groups** | Desktop application groups |
| **Scaling Plans** | Auto-scaling schedules for session hosts |
| **Session Host VMs** | Entra ID joined VMs from custom Compute Gallery images |

### Terraform Variables

#### `avd_config`

AVD environments are defined as a list. Each entry creates a complete set of AVD resources (host pool, workspace, app group, session hosts):

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Unique name for the AVD environment |
| `friendly_name` | string | Display name |
| `description` | string | Description (default: `"AVD Hostpool"`) |
| `type` | string | `"Pooled"` or `"Personal"` (default: `"Pooled"`) |
| `max_sessions` | number | Maximum concurrent sessions per host |
| `load_balancer_type` | string | `"DepthFirst"` or `"BreadthFirst"` |
| `vm_prefix` | string | Computer name prefix for session host VMs |
| `host_count` | number | Number of session host VMs to create |
| `image_name` | string | Image name in the Azure Compute Gallery |
| `app_group_type` | string | `"Desktop"` or `"RemoteApp"` |
| `vnet_name` / `vnet_rg` / `subnet_name` | string | Networking config for session hosts |

#### `sessionhosts`

| Field | Type | Description |
|-------|------|-------------|
| `size` | string | Azure VM SKU (e.g., `Standard_D4ads_v5`) |
| `local_admin` | string | Local admin username (default: `"shadmin"`) |
| `gallery_name` | string | Azure Compute Gallery name |
| `gallery_rg` | string | Compute Gallery resource group |

See [tf/ds.tfvars](tf/ds.tfvars) for a complete example.

## Tool Versions

| Tool | Version | Notes |
|------|---------|-------|
| Terraform | >= 1.0 | |
| AzureRM Provider | ~> 4.0 | |
| AzureAD Provider | ~> 2.53 | |
| Packer | >= 1.9 | |
| Packer Azure Plugin | ~> 2 | |
| Packer Windows Update Plugin | 0.16.8 | |

## Known Limitations

- **Local Terraform state** — State files are stored locally. For production use, configure a [remote backend](https://developer.hashicorp.com/terraform/language/backend/azurerm).
- **Registration token drift** — The AVD host pool registration token uses `timestamp()`, which triggers a diff on every `terraform plan`. This is expected behavior.
- **Profile storage** — FSLogix profile storage is currently disabled in `tf/main.tf`. Uncomment and configure for persistent user profiles.
