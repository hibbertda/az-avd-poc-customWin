output "host_pool_key" {
  value = azurerm_virtual_desktop_host_pool_registration_info.avd
}

output "host_pool" {
  value = azurerm_virtual_desktop_host_pool.hostpool
}