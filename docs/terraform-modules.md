# Terraform Modules

This document covers the two Terraform root modules and their child modules.

## Overview

| Root Module | Directory | Purpose |
|-------------|-----------|---------|
| **ENVSetup** | `terraform/ENVSetup/` | Creates the Compute Gallery and Image Definition — prerequisites for Packer |
| **AVD** | `terraform/AVD/` | Deploys the full AVD environment: networking, Key Vault, host pools, session hosts |

Both modules use:
- **AzureRM Provider** `~> 4.0`
- **Local state** (no remote backend configured)
- **Variables injected via `TF_VAR_*` environment variables** from the Makefile

The AVD module additionally uses the **AzureAD Provider** `~> 2.53` for Entra ID group and role management.

---

## ENVSetup Module

**Directory:** `terraform/ENVSetup/`

This is a simple, flat module (no child modules). It creates three resources:

| Resource | Type | Purpose |
|----------|------|---------|
| Resource Group | `azurerm_resource_group` | Container for the gallery |
| Compute Gallery | `azurerm_shared_image_gallery` | Stores versioned VM images |
| Image Definition | `azurerm_shared_image` | Defines OS type, Hyper-V generation, and publisher metadata |

### Key Variables

| Variable | Source in `.env` | Description |
|----------|-----------------|-------------|
| `resource_group_name` | `GALLERY_RG` | Resource group name |
| `gallery_name` | `GALLERY_NAME` | Compute Gallery name |
| `image_name` | `IMAGE_NAME` | Image definition name |
| `image_hyper_v_generation` | `IMAGE_HYPER_V_GEN` | `V1` or `V2` (default `V2`) |
| `image_publisher` / `image_offer` / `image_sku` | `IMAGE_PUBLISHER` / `IMAGE_OFFER` / `IMAGE_SKU` | Image identifier metadata |

### Why This Is Separate

The Compute Gallery must exist before Packer can publish to it. By keeping ENVSetup in its own root module, you can:
- Create the gallery once and rebuild images many times
- Destroy and recreate AVD without affecting the gallery
- Keep the gallery state independent of AVD state

---

## AVD Module

**Directory:** `terraform/AVD/`

This root module orchestrates four child modules and manages resource groups, RBAC, and the session host VM lifecycle.

### Resource Groups

The AVD module creates three resource groups per deployment:

| Resource Group | Name Pattern | Contents |
|---------------|-------------|----------|
| Core | `rg-avd-core-${location}-${uid}` | VNet, Key Vault |
| AVD Resources | `rg-avd-${pool}-resources-${uid}` | Host pool, workspace, app group (one per `avd_config` entry) |
| VMs | `rg-avd-${pool}-vms-${uid}` | Session host VMs and NICs (one per `avd_config` entry) |

### Child Modules

#### `modules/network/`

Creates the virtual network and subnets.

| Resource | Description |
|----------|-------------|
| `azurerm_virtual_network` | VNet with configurable address space |
| `azurerm_subnet` | One or more subnets (driven by the `subnets` variable) |

The VNet and subnet configuration is injected from `.env` via flat variables (`VNET_ADDRESS_SPACE`, `SUBNET_NAME`, `SUBNET_PREFIX`), which the root module composes into the object/list structures the module expects:

```hcl
module "network" {
  virtualnetwork = { address_space = var.vnet_address_space }
  subnets        = [{ name = var.subnet_name, address_prefix = var.subnet_prefix }]
}
```

#### `modules/keyvault/`

Creates an Azure Key Vault for storing generated secrets.

| Resource | Description |
|----------|-------------|
| `azurerm_key_vault` | Key Vault with access policies for the deploying user |

The Key Vault stores generated passwords. In this Entra ID-only deployment, there are no domain join credentials to store.

#### `modules/avd/`

Creates the AVD control plane resources for each host pool.

| Resource | Description |
|----------|-------------|
| `azurerm_virtual_desktop_host_pool` | Pooled or Personal host pool with Entra ID RDP properties |
| `azurerm_virtual_desktop_host_pool_registration_info` | Time-limited registration token for session host enrollment |
| `azurerm_virtual_desktop_workspace` | Workspace for the host pool |
| `azurerm_virtual_desktop_application_group` | Desktop application group |
| `azuread_group` | Entra ID security group for user assignment |
| `azurerm_role_assignment` | Desktop Virtualization User, VM User Login, Power On Contributor roles |
| `azurerm_virtual_desktop_scaling_plan` | Weekday/weekend scaling schedules |

**RDP Properties** — The host pool is configured with Entra ID join-specific RDP settings:

```
targetisaadjoined:i:1
enablerdsaadauth:i:1
```

**Scaling Plan** — Each host pool gets a scaling plan with weekday and weekend schedules:

| Period | Weekday | Weekend |
|--------|---------|---------|
| Ramp-up | 07:00 | 09:00 |
| Peak | 09:00 | 10:00 |
| Ramp-down | 17:00 | 16:00 |
| Off-peak | 19:00 | 18:00 |

#### `modules/aadjoined-sessionHostVM/`

Creates the Entra ID-joined session host VMs.

| Resource | Description |
|----------|-------------|
| `azurerm_network_interface` | NIC for each VM, attached to the VM subnet |
| `azurerm_windows_virtual_machine` | Windows VM from the custom gallery image, with SystemAssigned identity |
| `azurerm_virtual_machine_extension` (AADJoin) | `AADLoginForWindows` extension — joins VM to Entra ID |
| `azurerm_virtual_machine_extension` (RDAgent) | DSC extension — installs AVD agent and registers with host pool |
| `azurerm_virtual_machine_run_command` (Reboot) | Restarts the VM after all extensions complete |

Extensions run in a strict chain via `depends_on`:

```
VM → AADLoginForWindows → RDAgentInstall → Restart-Computer
```

---

## `avd_config` Variable

The `avd_config` variable is a list of objects defined in `terraform/AVD/avd.auto.tfvars`. Each entry creates a complete set of AVD resources: host pool, workspace, app group, and session hosts.

```hcl
avd_config = [{
  name           = "dev-pool"
  friendly_name  = "Developer Desktop"
  description    = "AVD pool for developer workstations"
  type           = "Pooled"
  max_sessions   = 4
  vm_prefix      = "dev"
  host_count     = 1
  image_name     = "developer"   # Must match IMAGE_NAME in .env
  app_group_type = "Desktop"
  subnet_name    = "vm"
  vnet_name      = ""            # Not used in Entra ID path
  vnet_rg        = ""            # Not used in Entra ID path
}]
```

### Field Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Unique identifier for this pool (used in resource naming) |
| `friendly_name` | string | required | Display name in the AVD portal |
| `description` | string | `"AVD Hostpool"` | Host pool description |
| `type` | string | `"Pooled"` | `"Pooled"` or `"Personal"` |
| `max_sessions` | number | required | Maximum concurrent sessions per host (Pooled only) |
| `load_balancer_type` | string | `"DepthFirst"` | `"DepthFirst"` or `"BreadthFirst"` |
| `vm_prefix` | string | required | Computer name prefix for VMs (e.g., `dev` → `avdsh-dev-0`) |
| `host_count` | number | `0` | Number of session host VMs to create |
| `image_name` | string | required | Image definition name in the Compute Gallery |
| `app_group_type` | string | `"Desktop"` | `"Desktop"` or `"RemoteApp"` |
| `vnet_name` / `vnet_rg` | string | — | Legacy fields for AD DS path (not used with Entra ID join) |
| `subnet_name` | string | required | Subnet name for session hosts |

### Multiple Pools

You can deploy multiple host pools by adding entries to the list:

```hcl
avd_config = [
  {
    name         = "dev-pool"
    friendly_name = "Developer Desktop"
    type         = "Pooled"
    max_sessions = 4
    vm_prefix    = "dev"
    host_count   = 2
    image_name   = "developer"
    # ...
  },
  {
    name         = "exec-pool"
    friendly_name = "Executive Desktop"
    type         = "Personal"
    max_sessions = 1
    vm_prefix    = "exec"
    host_count   = 3
    image_name   = "developer"
    # ...
  }
]
```

Each entry gets its own resource group, host pool, workspace, app group, Entra ID group, and session host VMs.

---

## Customization Guide

### Change VM Size

Update `SESSION_HOST_SIZE` in `.env`:

```
SESSION_HOST_SIZE=Standard_D8s_v5
```

### Change Network Configuration

Update in `.env`:

```
VNET_ADDRESS_SPACE=["10.20.0.0/16"]
SUBNET_NAME=session-hosts
SUBNET_PREFIX=["10.20.1.0/24"]
```

### Add More Session Hosts

Edit `host_count` in `terraform/AVD/avd.auto.tfvars`:

```hcl
host_count = 4
```

### Enable Profile Storage (FSLogix)

Uncomment the storage account and file share resources in `terraform/AVD/main.tf`. Configure AADKERB authentication for Entra ID-only environments.

### Add Bastion Host

Uncomment the Bastion resources in `terraform/AVD/modules/network/main.tf`. You'll need to add an `AzureBastionSubnet` to the subnets configuration.

### Switch to Remote Backend

Add a backend configuration to `terraform/AVD/providers.tf` and `terraform/ENVSetup/providers.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "avd.tfstate"
  }
}
```

---

## Known Behaviors

- **Registration token drift** — `azurerm_virtual_desktop_host_pool_registration_info` uses `timestamp()` for its expiration, which triggers a diff on every `terraform plan`. This is expected and harmless.
- **Role definition ID changes** — Role assignments use `lifecycle { ignore_changes = [role_definition_id] }` to prevent unnecessary updates when Azure updates role definition metadata.
- **Random UID** — A random 8-character string (`random_string.random_uid`) is generated per deployment. This ensures globally unique resource names and is tagged on the core resource group for reference.

---

Next: [Custom Images](custom-images.md) · [Makefile Reference](makefile-reference.md)
