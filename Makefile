# =============================================================================
# AVD Demo - Deployment Automation
# =============================================================================
# Usage:
#   1. Copy .env.example to .env and fill in your values
#   2. Run: make deploy-all    (full end-to-end deployment)
#
# Or run individual phases:
#   make deploy-env     → Create Resource Group + Compute Gallery
#   make build-images   → Build custom Windows image with Packer
#   make deploy-avd     → Deploy AVD infrastructure + session hosts
#
# Cleanup:
#   make destroy-all    → Tear down everything (reverse order)
# =============================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# Load environment configuration
# -----------------------------------------------------------------------------
ENV_FILE := .env
ifeq ($(wildcard $(ENV_FILE)),)
  $(warning WARNING: No .env file found. Copy .env.example to .env and fill in your values.)
endif
-include $(ENV_FILE)

# Directory paths
ROOT_DIR        := $(shell pwd)
ENV_SETUP_DIR   := $(ROOT_DIR)/terraform/ENVSetup
AVD_DIR         := $(ROOT_DIR)/terraform/AVD

# Image directory — selected by IMAGE_TYPE in .env (dev or data)
ifeq ($(IMAGE_TYPE),data)
  IMAGE_DIR := $(ROOT_DIR)/windows-data-image
else
  IMAGE_DIR := $(ROOT_DIR)/windows-dev-image
endif

# -----------------------------------------------------------------------------
# Terraform TF_VAR_ exports (simple string values)
# -----------------------------------------------------------------------------
export TF_VAR_az_subscription_id := $(AZ_SUBSCRIPTION_ID)
export TF_VAR_location           := $(AZ_LOCATION)
export TF_VAR_resource_group_name := $(GALLERY_RG)
export TF_VAR_gallery_name       := $(GALLERY_NAME)
export TF_VAR_gallery_description := $(GALLERY_DESCRIPTION)
export TF_VAR_image_name         := $(IMAGE_NAME)
export TF_VAR_image_os_type      := $(IMAGE_OS_TYPE)
export TF_VAR_image_hyper_v_generation := $(IMAGE_HYPER_V_GEN)
export TF_VAR_image_publisher    := $(IMAGE_PUBLISHER)
export TF_VAR_image_offer        := $(IMAGE_OFFER)
export TF_VAR_image_sku          := $(IMAGE_SKU)
export TF_VAR_session_host_size  := $(SESSION_HOST_SIZE)
export TF_VAR_local_admin        := $(LOCAL_ADMIN)
export TF_VAR_gallery_rg         := $(GALLERY_RG)

# Terraform TF_VAR_ exports (list/map values — Terraform parses these natively)
export TF_VAR_tags               := {"environment":"$(TAG_ENVIRONMENT)","project":"$(TAG_PROJECT)"}
export TF_VAR_vnet_address_space := $(VNET_ADDRESS_SPACE)
export TF_VAR_subnet_name       := $(SUBNET_NAME)
export TF_VAR_subnet_prefix     := $(SUBNET_PREFIX)

# -----------------------------------------------------------------------------
# Packer PKR_VAR_ exports (JSON-structured for object-typed variables)
# -----------------------------------------------------------------------------
export PKR_VAR_location          := $(AZ_LOCATION)
export PKR_VAR_cloud_environment := $(CLOUD_ENVIRONMENT)
export PKR_VAR_replication_regions := $(REPLICATION_REGIONS)
export PKR_VAR_az_compute_gallery := {"gallery_name":"$(GALLERY_NAME)","resource_group":"$(GALLERY_RG)"}
export PKR_VAR_build_vm          := {"size_sku":"$(BUILD_VM_SIZE)","os_disk_size":$(BUILD_VM_DISK_SIZE),"image_offer":"$(SOURCE_IMAGE_OFFER)","image_publisher":"$(SOURCE_IMAGE_PUBLISHER)","image_sku":"$(SOURCE_IMAGE_SKU)"}
export PKR_VAR_shared_image      := {"name":"$(IMAGE_NAME)","os_type":"$(IMAGE_OS_TYPE)","identifier":{"publisher":"$(IMAGE_PUBLISHER)","offer":"$(IMAGE_OFFER)","sku":"$(IMAGE_SKU)"}}

# =============================================================================
# Guard targets
# =============================================================================

.PHONY: auth-check
auth-check: # (internal) Verify Azure CLI authentication
	@echo "Checking Azure CLI authentication..."
	@az account show --query "{subscription:name, id:id, user:user.name}" -o table || \
		(echo "ERROR: Not logged in. Run 'az login' first." && exit 1)
	@echo "OK: Authenticated"

.PHONY: check-env
check-env:
	@if [ ! -f "$(ENV_FILE)" ]; then \
		echo "ERROR: No .env file found. Run: cp .env.example .env"; \
		exit 1; \
	fi

.PHONY: check-gallery
check-gallery: # (internal) Verify Compute Gallery exists before image build
	@echo "Checking Compute Gallery '$(GALLERY_NAME)' exists..."
	@az sig show \
		--resource-group "$(GALLERY_RG)" \
		--gallery-name "$(GALLERY_NAME)" \
		--query "name" -o tsv > /dev/null 2>&1 || \
		(echo "ERROR: Gallery '$(GALLERY_NAME)' not found in RG '$(GALLERY_RG)'. Run 'make deploy-env' first." && exit 1)
	@echo "OK: Gallery exists"

.PHONY: check-image
check-image: # (internal) Verify at least one image version exists before AVD deployment
	@echo "Checking image '$(IMAGE_NAME)' has at least one version..."
	@IMAGE_COUNT=$$(az sig image-version list \
		--resource-group "$(GALLERY_RG)" \
		--gallery-name "$(GALLERY_NAME)" \
		--gallery-image-definition "$(IMAGE_NAME)" \
		--query "length(@)" -o tsv 2>/dev/null); \
	if [ -z "$$IMAGE_COUNT" ] || [ "$$IMAGE_COUNT" -eq 0 ]; then \
		echo "ERROR: No image versions found for '$(IMAGE_NAME)'. Run 'make build-image' first."; \
		exit 1; \
	fi
	@echo "OK: Image version available"

# =============================================================================
# Phase 1: ENVSetup — Resource Group + Compute Gallery + Image Definition
# =============================================================================

.PHONY: deploy-env
deploy-env: check-env auth-check ## Deploy Compute Gallery + Image Definitions
	@echo "Deploying Compute Gallery and Image Definitions..."
	cd $(ENV_SETUP_DIR) && terraform init -input=false && terraform apply -auto-approve
	@echo "OK: ENVSetup complete"

.PHONY: destroy-env
destroy-env: check-env auth-check ## Destroy ENVSetup resources
	@echo "Destroying ENVSetup resources..."
	cd $(ENV_SETUP_DIR) && terraform destroy -auto-approve
	@echo "OK: ENVSetup destroyed"

# =============================================================================
# Phase 2: Packer Image Build
# =============================================================================

.PHONY: validate-image
validate-image: check-env check-gallery ## Validate Packer template for selected IMAGE_TYPE
	@echo "Validating $(IMAGE_TYPE) image template..."
	cd $(IMAGE_DIR) && packer init . && packer validate .
	@echo "OK: Packer template valid"

.PHONY: build-image
build-image: check-env auth-check check-gallery ## Build the custom image selected by IMAGE_TYPE
	@echo ""
	@echo "============================================================"
	@echo "  Building Image: $(IMAGE_TYPE)"
	@echo "  Template:  $(IMAGE_DIR)"
	@echo "  NOTE: Image builds typically take 30-60+ minutes"
	@echo "  The build VM must install updates, software, and sysprep"
	@echo "============================================================"
	@echo ""
	cd $(IMAGE_DIR) && packer init . && packer build .
	@echo "OK: Image build complete"

# =============================================================================
# Phase 3: AVD Infrastructure
# =============================================================================

.PHONY: deploy-avd
deploy-avd: check-env auth-check check-image ## Deploy AVD infrastructure + session hosts
	@echo "Deploying AVD infrastructure..."
	cd $(AVD_DIR) && terraform init -input=false && terraform apply -auto-approve
	@echo "OK: AVD deployment complete"

.PHONY: destroy-avd
destroy-avd: check-env auth-check ## Destroy AVD infrastructure
	@echo "Destroying AVD infrastructure..."
	cd $(AVD_DIR) && terraform destroy -auto-approve
	@echo "OK: AVD destroyed"

# =============================================================================
# Composite targets
# =============================================================================

.PHONY: deploy-all
deploy-all: check-env auth-check ## Full deployment: ENVSetup -> Packer -> AVD
	@echo ""
	@echo "============================================================"
	@echo "  Full AVD Demo Deployment"
	@echo "============================================================"
	@echo "  Phase 1: Compute Gallery + Image Definitions"
	@echo "  Phase 2: Custom Windows Image Build"
	@echo "  Phase 3: AVD Infrastructure + Session Hosts"
	@echo ""
	@echo "  TOTAL TIME: Expect 45-90+ minutes"
	@echo "  Most time is spent in Phase 2 (image build)"
	@echo "============================================================"
	@echo ""
	@echo ">> Phase 1: Deploying Compute Gallery..."
	@$(MAKE) deploy-env
	@echo ""
	@echo ">> Phase 2: Building Custom Image ($(IMAGE_TYPE))..."
	@echo "  This step typically takes 30-60+ minutes."
	@echo "  Packer will create a build VM, install Windows updates,"
	@echo "     configure software, sysprep, and capture the image."
	@echo ""
	@$(MAKE) build-image
	@echo ""
	@echo ">> Phase 3: Deploying AVD Infrastructure..."
	@$(MAKE) deploy-avd
	@echo ""
	@echo "============================================================"
	@echo "  Full deployment complete!"
	@echo "============================================================"

.PHONY: destroy-all
destroy-all: check-env auth-check ## Destroy everything (reverse order)
	@echo ""
	@echo "============================================================"
	@echo "  Destroying ALL AVD Demo Resources"
	@echo "  Order: AVD -> ENVSetup (reverse of deploy)"
	@echo "============================================================"
	@echo ""
	@$(MAKE) destroy-avd
	@$(MAKE) destroy-env
	@echo ""
	@echo "============================================================"
	@echo "  All resources destroyed"
	@echo "============================================================"

# =============================================================================
# Utility targets
# =============================================================================

.PHONY: validate
validate: check-env ## Validate all Terraform and Packer configs
	@echo "Validating ENVSetup..."
	cd $(ENV_SETUP_DIR) && terraform init -backend=false > /dev/null 2>&1 && terraform validate
	@echo "Validating AVD..."
	cd $(AVD_DIR) && terraform init -backend=false > /dev/null 2>&1 && terraform validate
	@echo "Validating $(IMAGE_TYPE) image..."
	cd $(IMAGE_DIR) && packer init . > /dev/null 2>&1 && packer validate .
	@echo "OK: All configs valid"

.PHONY: fmt
fmt: ## Format all Terraform and Packer files
	@echo "Formatting Terraform..."
	cd $(ENV_SETUP_DIR) && terraform fmt
	cd $(AVD_DIR) && terraform fmt
	@echo "Formatting Packer..."
	cd $(IMAGE_DIR) && packer fmt .
	@echo "OK: All files formatted"

.PHONY: clean
clean: ## Remove local Terraform state and plugin caches
	@echo "Cleaning Terraform working directories..."
	rm -rf $(ENV_SETUP_DIR)/.terraform
	rm -rf $(AVD_DIR)/.terraform
	rm -f $(ENV_SETUP_DIR)/.terraform.lock.hcl
	rm -f $(AVD_DIR)/.terraform.lock.hcl
	@echo "OK: Clean complete"

.PHONY: help
help: ## Show this help message
	@printf "\n"
	@printf "AVD Demo — Makefile Targets\n"
	@printf "===========================\n"
	@printf "\n"
	@printf "  \033[1mFull Deployment:\033[0m\n"
	@printf "    \033[36mdeploy-all\033[0m       Deploy everything (ENVSetup -> Packer -> AVD)\n"
	@printf "    \033[36mdestroy-all\033[0m      Tear down everything (reverse order)\n"
	@printf "\n"
	@printf "  \033[1mPhase 1 — Compute Gallery:\033[0m\n"
	@printf "    \033[36mdeploy-env\033[0m       Create Resource Group + Gallery + Image Definition\n"
	@printf "    \033[36mdestroy-env\033[0m      Destroy ENVSetup resources\n"
	@printf "\n"
	@printf "  \033[1mPhase 2 — Packer Image Build:\033[0m  (IMAGE_TYPE=$(IMAGE_TYPE))\n"
	@printf "    \033[36mbuild-image\033[0m      Build the custom image for selected IMAGE_TYPE\n"
	@printf "\n"
	@printf "  \033[1mPhase 3 — AVD Infrastructure:\033[0m\n"
	@printf "    \033[36mdeploy-avd\033[0m       Deploy host pools, networking + session hosts\n"
	@printf "    \033[36mdestroy-avd\033[0m      Destroy AVD infrastructure\n"
	@printf "\n"
	@printf "  \033[1mUtilities:\033[0m\n"
	@printf "    \033[36mvalidate\033[0m         Validate all Terraform and Packer configs\n"
	@printf "    \033[36mvalidate-image\033[0m   Validate Packer template for selected IMAGE_TYPE\n"
	@printf "    \033[36mfmt\033[0m              Format all Terraform and Packer files\n"
	@printf "    \033[36mclean\033[0m            Remove local Terraform state and plugin caches\n"
	@printf "\n"
	@printf "  Quick start:\n"
	@printf "    1. cp .env.example .env    # Configure your environment\n"
	@printf "    2. make deploy-all         # Deploy everything\n"
	@printf "\n"
