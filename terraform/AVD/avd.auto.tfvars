# =============================================================================
# AVD-specific configuration
# =============================================================================
# This file contains the complex AVD configuration that doesn't belong in .env.
# Values like location, subscription_id, gallery_name, gallery_rg, tags,
# session_host_size, and local_admin are injected via TF_VAR_* from .env.
#
# Edit this file to customize your AVD hostpool and networking setup.
# =============================================================================

# --- AVD Host Pool Configuration ---
# Each entry creates a hostpool + workspace + app group + session hosts.
# The image_name must match the IMAGE_NAME in your .env file.

avd_config = [{
  name           = "dev-pool"
  friendly_name  = "Developer Desktop"
  description    = "AVD pool for developer workstations"
  type           = "Pooled"
  max_sessions   = 4
  vm_prefix      = "dev"
  host_count     = 1
  image_name     = "developer" # Must match IMAGE_NAME in .env
  app_group_type = "Desktop"

  # These are populated at plan-time from the core VNet created by this module.
  # Update if you change the subnet name in .env (SUBNET_NAME).
  vnet_name   = "" # Filled dynamically — see note below
  vnet_rg     = "" # Filled dynamically — see note below
  subnet_name = "vm"
}]

# NOTE: vnet_name and vnet_rg in avd_config above are only used by the legacy
# sessionHostVM module (AD DS joined). The aadjoined-sessionHostVM module
# uses core_virtualnetwork passed directly from the network module output,
# so these values are not consumed in the current Entra ID deployment path.
