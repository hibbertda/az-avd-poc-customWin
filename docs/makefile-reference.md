# Makefile Reference

The Makefile automates all deployment, validation, and cleanup tasks. It reads configuration from `.env` and translates values into `TF_VAR_*` and `PKR_VAR_*` environment variables that Terraform and Packer consume natively.

## Usage

```bash
make <target>
```

Run `make help` to see all available targets grouped by phase.

## Targets

### Full Deployment

| Target | Description |
|--------|-------------|
| `deploy-all` | Run all three phases in order: ENVSetup → Packer → AVD. Expect 45-90 minutes total. |
| `destroy-all` | Tear down everything in reverse order: AVD → ENVSetup. |

### Phase 1 — Compute Gallery

| Target | Description |
|--------|-------------|
| `deploy-env` | Create the Resource Group, Compute Gallery, and Image Definition. |
| `destroy-env` | Destroy the ENVSetup resources. |

### Phase 2 — Packer Image Build

| Target | Description |
|--------|-------------|
| `build-image` | Build the custom Windows image using the template selected by `IMAGE_TYPE` in `.env`. Takes 30-60+ minutes. |
| `validate-image` | Validate the Packer template syntax without building. |

### Phase 3 — AVD Infrastructure

| Target | Description |
|--------|-------------|
| `deploy-avd` | Deploy VNet, Key Vault, host pools, and session host VMs. |
| `destroy-avd` | Destroy AVD infrastructure. |

### Utilities

| Target | Description |
|--------|-------------|
| `validate` | Validate all Terraform configs and the selected Packer template. |
| `fmt` | Format all Terraform and Packer files. |
| `clean` | Remove local `.terraform` directories and lock files. |
| `help` | Show the grouped help menu. |

## Guard Targets (Internal)

These run automatically as prerequisites. You don't need to call them directly.

| Target | Runs Before | Purpose |
|--------|-------------|---------|
| `auth-check` | All deploy/destroy targets | Verifies `az login` session is active. |
| `check-env` | Everything | Verifies `.env` exists. |
| `check-gallery` | `build-image`, `validate-image` | Verifies the Compute Gallery exists in Azure. |
| `check-image` | `deploy-avd` | Verifies at least one image version exists in the gallery. |

## Environment Variables

The Makefile reads `.env` and exports the following for Terraform and Packer:

### Terraform Variables (`TF_VAR_*`)

| `.env` Key | Terraform Variable | Used In |
|------------|-------------------|---------|
| `AZ_SUBSCRIPTION_ID` | `az_subscription_id` | ENVSetup, AVD |
| `AZ_LOCATION` | `location` | ENVSetup, AVD |
| `GALLERY_RG` | `resource_group_name`, `gallery_rg` | ENVSetup, AVD |
| `GALLERY_NAME` | `gallery_name` | ENVSetup, AVD |
| `GALLERY_DESCRIPTION` | `gallery_description` | ENVSetup |
| `IMAGE_NAME` | `image_name` | ENVSetup |
| `IMAGE_OS_TYPE` | `image_os_type` | ENVSetup |
| `IMAGE_HYPER_V_GEN` | `image_hyper_v_generation` | ENVSetup |
| `IMAGE_PUBLISHER` | `image_publisher` | ENVSetup |
| `IMAGE_OFFER` | `image_offer` | ENVSetup |
| `IMAGE_SKU` | `image_sku` | ENVSetup |
| `SESSION_HOST_SIZE` | `session_host_size` | AVD |
| `LOCAL_ADMIN` | `local_admin` | AVD |
| `VNET_ADDRESS_SPACE` | `vnet_address_space` | AVD |
| `SUBNET_NAME` | `subnet_name` | AVD |
| `SUBNET_PREFIX` | `subnet_prefix` | AVD |
| `TAG_ENVIRONMENT` + `TAG_PROJECT` | `tags` | AVD |

### Packer Variables (`PKR_VAR_*`)

| `.env` Key(s) | Packer Variable | Format |
|---------------|----------------|--------|
| `AZ_LOCATION` | `location` | String |
| `CLOUD_ENVIRONMENT` | `cloud_environment` | String |
| `REPLICATION_REGIONS` | `replication_regions` | JSON array |
| `GALLERY_NAME` + `GALLERY_RG` | `az_compute_gallery` | JSON object |
| `BUILD_VM_SIZE` + `BUILD_VM_DISK_SIZE` + source image vars | `build_vm` | JSON object |
| `IMAGE_NAME` + `IMAGE_OS_TYPE` + identifier vars | `shared_image` | JSON object |

## How It Works

1. `make` includes `.env` using `-include $(ENV_FILE)`
2. Each `.env` key is mapped to a `TF_VAR_*` or `PKR_VAR_*` export
3. For complex variables (objects, lists), the Makefile composes JSON inline from individual `.env` values
4. Terraform and Packer read these environment variables natively — no `-var-file` needed
5. The `avd.auto.tfvars` file handles the complex `avd_config` list that doesn't map well to flat environment variables

## IMAGE_TYPE Routing

The `IMAGE_TYPE` variable in `.env` controls which Packer template directory is used:

| `IMAGE_TYPE` | Directory | Template |
|-------------|-----------|----------|
| `dev` | `windows-dev-image/` | Developer workstation image (Windows 11, VS Code, Git, etc.) |
| `data` | `windows-data-image/` | Data analyst image (Windows 10/11, Power BI, Python, etc.) |

This is evaluated at Makefile parse time using a conditional:

```makefile
ifeq ($(IMAGE_TYPE),data)
  IMAGE_DIR := $(ROOT_DIR)/windows-data-image
else
  IMAGE_DIR := $(ROOT_DIR)/windows-dev-image
endif
```

## Examples

```bash
# Validate everything before deploying
make validate

# Deploy just the gallery, then iterate on images
make deploy-env
make build-image

# Rebuild AVD session hosts after image update
make destroy-avd
make deploy-avd

# Format all code
make fmt

# Clean up local Terraform caches
make clean
```

---

Next: [Getting Started](getting-started.md) · [Architecture](architecture.md)
