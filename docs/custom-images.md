# Custom Images

This demo uses [HashiCorp Packer](https://www.packer.io/) to build custom Windows images and publish them to an Azure Compute Gallery. Session host VMs are then deployed from these images.

## How Image Builds Work

Every build follows the same lifecycle:

```
Azure Marketplace Image
  └─▶ Provision temporary Build VM
        └─▶ Windows Update (all available patches)
              └─▶ Install software (Chocolatey)
                    └─▶ Sysprep (generalize)
                          └─▶ Capture → Managed Image
                                └─▶ Publish to Compute Gallery
                                      └─▶ Delete Build VM (automatic)
```

### Automatic Versioning

Each build is automatically versioned using the current timestamp:

```hcl
locals {
  shared_image_version = formatdate("YY.MM.DDhhmm", timestamp())
}
```

This produces versions like `25.06.151430`, ensuring every build gets a unique version in the gallery without manual incrementing.

## Image Types

The `IMAGE_TYPE` variable in `.env` selects which template to build:

### Developer Image (`IMAGE_TYPE=dev`)

**Directory:** `windows-dev-image/`

| Setting | Value |
|---------|-------|
| Base OS | Windows 11 24H2 Enterprise |
| Hyper-V Gen | V2 |
| Installed Software | VS Code, Google Chrome, Git, PuTTY, Az PowerShell, Azure CLI, Storage Explorer, AzCopy, Power BI, Python |

### Data Analyst Image (`IMAGE_TYPE=data`)

**Directory:** `windows-data-image/`

A second template for data-focused workloads. Customize the install script to include tools like SSMS, Power BI, R, or Jupyter.

## Packer Template Structure

Each image directory contains:

```
windows-dev-image/
  ├── windows-dev-image.pkr.hcl    # Main template (source + build blocks)
  ├── variables.pkr.hcl            # Variable definitions
  └── scripts/
      ├── install.ps1              # Software installation
      ├── remove-choco.ps1         # Chocolatey cleanup (optional)
      └── sysprep.ps1              # Image generalization
```

### Template Breakdown

**Plugin requirements** — The Azure plugin (`~> 2`) handles VM provisioning and gallery publishing. The `windows-update` plugin (`0.16.8`) patches the OS.

```hcl
packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
    windows-update = {
      source  = "github.com/rgl/windows-update"
      version = "0.16.8"
    }
  }
}
```

**Source block** — Defines the build VM configuration and gallery destination. Key settings:

| Setting | Purpose |
|---------|---------|
| `use_azure_cli_auth = true` | Authenticates using your active `az login` session |
| `communicator = "winrm"` | Uses WinRM to connect to the build VM |
| `shared_image_gallery_destination` | Publishes the final image to the Compute Gallery |

**Build block** — Defines the provisioning steps:

```hcl
build {
  sources = ["source.azure-arm.win11"]

  provisioner "windows-update" {}       # Patch the OS

  provisioner "powershell" {
    script = "./scripts/install.ps1"    # Install your software
  }

  provisioner "powershell" {
    script = "./scripts/sysprep.ps1"    # Generalize
  }
}
```

## Customizing the Install Script

The `scripts/install.ps1` file is where you define what software goes into the image. It uses [Chocolatey](https://chocolatey.org/) for package management.

### Adding a Package

Add a line to `install.ps1`:

```powershell
choco install <package-name> --confirm
```

Find packages at [https://community.chocolatey.org/packages](https://community.chocolatey.org/packages).

### Example: Adding Node.js and Docker CLI

```powershell
choco install nodejs-lts --confirm
choco install docker-cli --confirm
```

### Using MSI or EXE Installers

For software not in the Chocolatey repository, download and install directly:

```powershell
Invoke-WebRequest -Uri "https://example.com/installer.msi" -OutFile "C:\installer.msi"
Start-Process msiexec.exe -ArgumentList "/i C:\installer.msi /quiet" -Wait
Remove-Item "C:\installer.msi"
```

### Adding Files to the Image

Use Packer's `file` provisioner to copy files into the build VM:

```hcl
provisioner "file" {
  source      = "./app_images/wallpaper.png"
  destination = "C:\\Windows\\Web\\Wallpaper\\custom.png"
}
```

## Variables

All Packer variables are injected via `PKR_VAR_*` environment variables from the Makefile. No `-var-file` is needed.

| Variable | Type | Source in `.env` |
|----------|------|-----------------|
| `location` | string | `AZ_LOCATION` |
| `cloud_environment` | string | `CLOUD_ENVIRONMENT` |
| `replication_regions` | list(string) | `REPLICATION_REGIONS` |
| `az_compute_gallery` | object | Composed from `GALLERY_NAME` + `GALLERY_RG` |
| `build_vm` | object | Composed from `BUILD_VM_SIZE`, `BUILD_VM_DISK_SIZE`, source image vars |
| `shared_image` | object | Composed from `IMAGE_NAME`, `IMAGE_OS_TYPE`, identifier vars |

## Building Manually

While `make build-image` is the recommended approach, you can build directly:

```bash
cd windows-dev-image
packer init .
packer validate .
packer build .
```

Environment variables (`PKR_VAR_*`) must be set — either export them manually or source the Makefile exports.

## Build Timing

| Phase | Typical Duration |
|-------|-----------------|
| VM provisioning | 3-5 minutes |
| Windows Update | 10-30 minutes |
| Software install | 5-15 minutes |
| Sysprep | 3-5 minutes |
| Image capture + publish | 5-10 minutes |
| **Total** | **30-60+ minutes** |

Windows Update is the primary variable. A fresh marketplace image may have many patches to apply.

## Troubleshooting

### Build hangs on Windows Update

This is normal for the first build from a new marketplace image. Let it run — it can take 30+ minutes.

### WinRM connection timeout

Increase `winrm_timeout` in the template (default is `5m`). Some Windows updates require reboots that extend the connection time.

### "Duplicate variable" error

Ensure there is only one `.pkr.hcl` template file in the image directory. Check for leftover files with typos in the name.

---

Next: [Terraform Modules](terraform-modules.md) · [Architecture](architecture.md)
