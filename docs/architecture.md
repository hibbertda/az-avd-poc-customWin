# Architecture

This document explains the deployment model, identity strategy, and resource topology used by the AVD demo.

## Deployment Phases

The deployment is split into three independent phases. Each phase produces resources that the next phase depends on, but they are **decoupled** — there is no shared Terraform state between phases. The Makefile orchestrates the order.

```
Phase 1: ENVSetup          Phase 2: Packer             Phase 3: AVD
┌─────────────────┐        ┌─────────────────┐         ┌──────────────────────┐
│ Resource Group   │        │ Build VM (temp)  │         │ VNet + Subnets       │
│ Compute Gallery  │───────▶│ Windows Update   │────────▶│ Key Vault            │
│ Image Definition │        │ Install Software │         │ Host Pool + Workspace│
└─────────────────┘        │ Sysprep          │         │ Application Group    │
                           │ Publish to Gallery│         │ Scaling Plan         │
                           └─────────────────┘         │ Session Host VMs     │
                                                       │ Entra ID Join        │
                                                       │ RD Agent Install     │
                                                       │ VM Reboot            │
                                                       └──────────────────────┘
```

### Why Three Phases?

| Reason | Details |
|--------|---------|
| **Separation of concerns** | Gallery infrastructure, image content, and AVD resources change independently. |
| **Build time** | Image builds take 30-60+ minutes. Separating them means AVD infra changes don't trigger a rebuild. |
| **Iterability** | Rebuild an image without touching AVD. Redeploy AVD without rebuilding the image. Destroy and recreate any layer independently. |
| **No state coupling** | Each Terraform root module has its own state. There is no `terraform_remote_state` data source between them. Phases communicate through Azure resource names defined in `.env`. |

## Identity Model — Entra ID Join

This demo uses **Microsoft Entra ID join** exclusively. There is no dependency on Active Directory Domain Services (AD DS), Azure AD DS, or any domain controller.

### How It Works

1. **VM Creation** — Session host VMs are created with a `SystemAssigned` managed identity.
2. **Entra ID Join** — The `AADLoginForWindows` VM extension joins the VM to your Entra ID tenant. No domain credentials, no network line-of-sight to a DC.
3. **RD Agent Registration** — The DSC extension installs the AVD agent and registers the VM with its host pool using a time-limited registration token.
4. **Reboot** — A run command issues `Restart-Computer` to ensure all extensions and policies take effect.
5. **User Authentication** — Users sign in with their Entra ID credentials. The host pool RDP properties include `targetisaadjoined:i:1` and `enablerdsaadauth:i:1`.

### Extension Chain

Extensions on each session host VM run in strict order via `depends_on`:

```
VM Created
  └─▶ AADLoginForWindows (Entra ID Join)
        └─▶ DSC / RDAgentInstall (Register with Host Pool)
              └─▶ Run Command: Restart-Computer
```

### Compared to AD DS Join

| | Entra ID Join (this demo) | AD DS Join (traditional) |
|---|---|---|
| Domain controllers | Not required | Required (on-prem or Azure) |
| VPN / ExpressRoute | Not required | Often required |
| Group Policy | Intune / Entra ID conditional access | Traditional GPO |
| Complexity | Low | High |
| Best for | Demos, cloud-native orgs, SMBs | Enterprises with existing AD DS |

## Resource Topology

A typical deployment creates the following resource groups and resources:

### ENVSetup Resources

| Resource | Name Pattern | Purpose |
|----------|-------------|---------|
| Resource Group | `${GALLERY_RG}` (e.g., `AVD_Demo_Resources`) | Holds the gallery and image definitions |
| Compute Gallery | `${GALLERY_NAME}` | Stores versioned VM images |
| Image Definition | `${IMAGE_NAME}` | Defines the OS type, generation, and publisher metadata |

### AVD Resources

| Resource | Name Pattern | Purpose |
|----------|-------------|---------|
| Core Resource Group | `rg-avd-core-${location}-${uid}` | VNet, Key Vault |
| AVD Resource Group | `rg-avd-${pool-name}-resources-${uid}` | Host pool, workspace, app group |
| VM Resource Group | `rg-avd-${pool-name}-vms-${uid}` | Session host VMs and NICs |
| Virtual Network | `vnet-avd-${uid}` | Isolated network for session hosts |
| Key Vault | `kv-avd-${uid}` | Stores generated admin passwords |
| Host Pool | `hp-${pool-name}-${uid}` | AVD host pool (Pooled or Personal) |
| Workspace | `avdwksp-${pool-name}-${uid}` | AVD workspace |
| Application Group | `avdag-${pool-name}-${uid}-desktop` | Desktop app group |
| Entra ID Group | `avd-${pool-name}-${uid}-users` | Security group for user assignment |
| Session Host VMs | `avdsh-${prefix}-${n}` | Windows VMs running the custom image |

> `${uid}` is a random 8-character string generated per deployment to ensure globally unique names.

## Networking

The deployment creates a simple flat network:

- **VNet** with a configurable address space (default `10.12.0.0/16`)
- **VM Subnet** for session host NICs (default `10.12.1.0/24`)
- No NSGs, peering, or Bastion by default (templates for Bastion are commented out in the network module)

For production use, you would add NSGs, private endpoints, and potentially peering to a hub network.

## Scaling

The AVD module includes a scaling plan that is created and associated with each host pool. This uses Azure's built-in AVD scaling functionality to start and stop VMs based on session demand.

## State Management

Both Terraform root modules use **local state** by default. This is intentional for a demo — each clone of the repo gets its own state.

For team or production use, configure a [remote backend](https://developer.hashicorp.com/terraform/language/backend/azurerm):

```hcl
backend "azurerm" {
  resource_group_name  = "rg-terraform-state"
  storage_account_name = "stterraformstate"
  container_name       = "tfstate"
  key                  = "avd-demo.tfstate"
}
```

---

Next: [Custom Images](custom-images.md) · [Terraform Modules](terraform-modules.md)
