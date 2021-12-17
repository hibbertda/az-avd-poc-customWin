variable "env" {
  type = map
}

variable "network" {
  type = map
}

variable "rgName" {
    type = string
}

# Current user will be added to KeyVault access policy
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                        = "kv-${var.env["name"]}"
  location                    = var.env["region"]
  resource_group_name         = var.rgName
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Backup",
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "Recover",
      "Restore",
      "SetIssuers",
      "Update"
    ]
  }
}