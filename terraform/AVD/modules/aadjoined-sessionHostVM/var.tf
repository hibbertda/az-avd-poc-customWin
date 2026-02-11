variable "resourcegroup" {}
#variable "subnet" {}
variable "sessionhosts" {}
variable "host_pool_key" {}
variable "host_pool" {}
variable "avd_config" {}
# Remove AD DS variables since we're using pure Entra ID
# variable "adds-join-username" {}
# variable "adds-join-password" {}
variable "tags" {}
variable "core_resourcegroup" {
  
}
variable "core_virtualnetwork" {
  
}