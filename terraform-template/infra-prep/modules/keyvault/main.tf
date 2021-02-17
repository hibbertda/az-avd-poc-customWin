# Create KeyVault and grant current user with access policy to manage secrets
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "wvd-keyvault" {
    name                        = "kv-${var.env["envName"]}-${var.env["region"]}"
    location                    = var.rgLocation
    resource_group_name         = var.rgName
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    enabled_for_disk_encryption = false
    sku_name                    = "standard"

    access_policy {
        tenant_id               = data.azurerm_client_config.current.tenant_id
        object_id               = data.azurerm_client_config.current.object_id

        secret_permissions  = [
            "get",
            "list",
            "purge",
            "recover",
            "restore",
            "backup",
            "set",
            "delete"
        ]
    }

}

# Output vm-admin password secret
resource "azurerm_key_vault_secret" "adminPassword" {
    name = "vm-adminpassword"
    value = var.vm-admin-password

    key_vault_id = azurerm_key_vault.wvd-keyvault.id
}

# Output vm-admin username secret
resource "azurerm_key_vault_secret" "adminusername" {
    name = "vm-adminusername"
    value = "wvdadmin"

    key_vault_id = azurerm_key_vault.wvd-keyvault.id
}

resource "azurerm_key_vault_secret" "domainjoin-username" {
    name = "domainjoin-username"
    value = var.adds-join-username

    key_vault_id = azurerm_key_vault.wvd-keyvault.id
}


resource "azurerm_key_vault_secret" "domainjoin-password" {
    name = "domainjoin-password"
    value = var.vm-admin-password

    key_vault_id = azurerm_key_vault.wvd-keyvault.id
}
