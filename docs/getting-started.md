# Getting Started

This guide walks through configuring and deploying the AVD demo environment from scratch.

## Prerequisites

Install the following tools before proceeding:

| Tool | Minimum Version | Install Guide |
|------|-----------------|---------------|
| Azure CLI | 2.50+ | [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| Terraform | 1.0+ | [Install Terraform](https://developer.hashicorp.com/terraform/install) |
| Packer | 1.9+ | [Install Packer](https://developer.hashicorp.com/packer/install) |
| GNU Make | Any | Pre-installed on macOS/Linux. Windows users can use WSL or [chocolatey](https://community.chocolatey.org/packages/make). |

You also need:

- An **Azure Subscription** with permissions to create resource groups, VMs, virtual networks, Key Vaults, and AVD resources.
- A **Microsoft Entra ID tenant** — the deploying user is automatically added to the AVD user group.

## 1. Configure the Environment

All deployment settings live in a single `.env` file at the repo root.

```bash
cp .env.example .env
```

Open `.env` and set the required values:

### Required Settings

| Variable | Example | Description |
|----------|---------|-------------|
| `AZ_SUBSCRIPTION_ID` | `00000000-...` | Your Azure subscription ID. Find it with `az account show --query id -o tsv`. |
| `AZ_LOCATION` | `centralus` | Azure region for all resources. |
| `GALLERY_RG` | `AVD_Demo_Resources` | Resource group name for the Compute Gallery (created automatically). |
| `GALLERY_NAME` | `mclab_avd_images` | Name for the Azure Compute Gallery. |
| `IMAGE_NAME` | `developer` | Image definition name. Must match the `image_name` field in `avd.auto.tfvars`. |
| `IMAGE_TYPE` | `dev` | Which Packer template to build: `dev` (windows-dev-image) or `data` (windows-data-image). |

### Optional Settings

Most other values have sensible defaults. Common ones to adjust:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLOUD_ENVIRONMENT` | `Public` | Set to `USGovernment` for Azure Gov. |
| `SESSION_HOST_SIZE` | `Standard_D4s_v5` | VM SKU for session hosts. |
| `BUILD_VM_SIZE` | `Standard_D2s_v3` | VM SKU for the Packer build VM. |
| `IMAGE_HYPER_V_GEN` | `V2` | Hyper-V generation. `V2` required for Windows 11. |
| `VNET_ADDRESS_SPACE` | `["10.12.0.0/16"]` | VNet CIDR block. |
| `SUBNET_NAME` / `SUBNET_PREFIX` | `vm` / `["10.12.1.0/24"]` | Session host subnet. |

See `.env.example` for the full list with inline documentation.

## 2. Authenticate to Azure

```bash
az login
```

If you have multiple subscriptions, set the active one:

```bash
az account set --subscription "<your-subscription-id>"
```

Verify your authentication:

```bash
az account show --query "{subscription:name, id:id}" -o table
```

## 3. Deploy

### Option A: Full Deployment (Recommended)

Deploy everything in one command:

```bash
make deploy-all
```

This runs three phases in order:

1. **ENVSetup** — Creates the Resource Group, Compute Gallery, and Image Definition (~2 minutes)
2. **Packer Build** — Builds the custom Windows image (~30-60 minutes)
3. **AVD Deploy** — Creates networking, host pools, and session host VMs (~10-15 minutes)

Total time: **45-90 minutes** (image build is the bottleneck).

### Option B: Phase by Phase

Run each phase independently:

```bash
make deploy-env       # Phase 1: Compute Gallery
make build-image      # Phase 2: Packer image build
make deploy-avd       # Phase 3: AVD infrastructure
```

This is useful when iterating — for example, rebuilding an image without redeploying AVD.

## 4. Validate the Deployment

After deployment completes:

1. Open the [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Virtual Desktop** → **Host pools**
3. Verify your host pool shows the expected number of session hosts with status **Available**
4. Go to **Workspaces** → open your workspace → verify the Desktop application group is attached
5. Connect using the [AVD client](https://learn.microsoft.com/en-us/azure/virtual-desktop/users/connect-windows) or the web client at [https://client.wvd.microsoft.com](https://client.wvd.microsoft.com)

## 5. Clean Up

Tear down all resources when you're done:

```bash
make destroy-all
```

This destroys in reverse order (AVD first, then ENVSetup). You can also destroy phases individually:

```bash
make destroy-avd      # Remove AVD infrastructure only
make destroy-env      # Remove Compute Gallery only
```

> **Note:** The Packer-built image versions in the Compute Gallery are not destroyed by `make destroy-avd`. They are removed when the gallery itself is destroyed via `make destroy-env`.

## Troubleshooting

### "No .env file found"

```bash
cp .env.example .env
# Edit .env with your values
```

### "Not logged in"

```bash
az login
```

### "Gallery not found" when running `make build-image`

Run `make deploy-env` first to create the Compute Gallery.

### "No image versions found" when running `make deploy-avd`

Run `make build-image` first to build and publish an image to the gallery.

### Packer build times out

Increase the build VM size in `.env` (`BUILD_VM_SIZE`) or check your network connectivity. Windows Update and software installs can be slow on smaller VMs.

### `image_name` mismatch

The `IMAGE_NAME` in `.env` must match the `image_name` field inside `terraform/AVD/avd.auto.tfvars`. If you change one, update the other.

---

Next: [Architecture Overview](architecture.md) · [Makefile Reference](makefile-reference.md)
