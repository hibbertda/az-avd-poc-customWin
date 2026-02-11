# Azure Virtual Desktop — Custom Image Demo

A turnkey demo for deploying **Azure Virtual Desktop (AVD)** with **Entra ID joined** session hosts running custom Windows images — no Active Directory required.

Use this repo to stand up a complete AVD environment in under two hours, then tear it down when you're done. Fork or clone it as a starting point for your own AVD architecture.

## What It Deploys

| Layer | What Gets Created |
|-------|-------------------|
| **Compute Gallery** | Resource Group, Azure Compute Gallery, Image Definition |
| **Custom Image** | Windows 11 VM image with your software pre-installed (VS Code, Git, Azure CLI, etc.) |
| **AVD Infrastructure** | VNet, Key Vault, Host Pool, Workspace, Application Group, Scaling Plan, Entra ID-joined Session Host VMs |

## Why This Architecture

- **No domain controllers** — Session hosts join Microsoft Entra ID directly, eliminating AD DS infrastructure, VPN tunnels, and domain trust complexity.
- **Custom golden images** — Packer builds reproducible Windows images with pre-installed tools, published to an Azure Compute Gallery for versioning and replication.
- **Single config file** — One `.env` file drives all three deployment phases. No jumping between tfvars, pkrvars, and parameter files.
- **Make-driven workflow** — `make deploy-all` runs the entire pipeline. Individual phases can be run or destroyed independently.

## Quick Start

```bash
# 1. Clone and configure
git clone <this-repo>
cd az-avd-poc-customWin
cp .env.example .env         # Edit with your subscription, region, and preferences

# 2. Authenticate
az login

# 3. Deploy everything
make deploy-all               # Creates gallery → builds image → deploys AVD (~60-90 min)

# 4. Clean up when done
make destroy-all
```

Run `make help` for all available targets.

## Prerequisites

- **Azure Subscription** with permissions to create VMs, networking, and AVD resources
- **Azure CLI** ([install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Terraform** ≥ 1.0 ([install](https://developer.hashicorp.com/terraform/install))
- **Packer** ≥ 1.9 ([install](https://developer.hashicorp.com/packer/install))
- **GNU Make**

## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Environment setup, `.env` configuration, and first deployment walkthrough |
| [Architecture](docs/architecture.md) | Deployment phases, Entra ID join model, and resource topology |
| [Custom Images](docs/custom-images.md) | Packer image build process, install scripts, and image types |
| [Terraform Modules](docs/terraform-modules.md) | ENVSetup and AVD module breakdown, `avd_config`, and customization |
| [Makefile Reference](docs/makefile-reference.md) | All targets, environment variables, and usage examples |

## Repository Layout

```
.env.example                  # Master config template — copy to .env
Makefile                      # Deployment automation
terraform/
  ENVSetup/                   # Phase 1: Resource Group + Compute Gallery
  AVD/                        # Phase 3: Host Pools, Networking, Session Hosts
    modules/
      avd/                    #   Host pool, workspace, app group, scaling plan
      network/                #   VNet + subnets
      keyvault/               #   Key Vault for secrets
      aadjoined-sessionHostVM/#   Entra ID joined session host VMs
windows-dev-image/            # Phase 2: Packer template — developer image
windows-data-image/           # Phase 2: Packer template — data analyst image
docs/                         # Detailed documentation
```

## License

This project is provided as a demo and reference architecture. Use at your own discretion.
