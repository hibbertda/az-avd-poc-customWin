# Create KeyVault and grant current user with access policy to manage secrets
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "wvd-keyvault" {
    name                        = "kv-avd-${var.random}"
    location                    = var.resourcegroup.location
    resource_group_name         = var.resourcegroup.name
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    enabled_for_disk_encryption = false
    sku_name                    = "standard"

    access_policy {
        tenant_id               = data.azurerm_client_config.current.tenant_id
        object_id               = data.azurerm_client_config.current.object_id

        secret_permissions  = [
            "Get",
            "List",
            "Purge",
            "Recover",
            "Restore",
            "Backup",
            "Set",
            "Delete"
        ]
    }

}

# Remove AD DS secrets since we're using pure Entra ID
# resource "azurerm_key_vault_secret" "domainjoin-username" {
#     name = "domainjoin-username"
#     value = var.adds-join-username

#     key_vault_id = azurerm_key_vault.wvd-keyvault.id
# }


# resource "azurerm_key_vault_secret" "domainjoin-password" {
#     name = "domainjoin-password"
#     value = var.adds-join-password

#     key_vault_id = azurerm_key_vault.wvd-keyvault.id
# }
