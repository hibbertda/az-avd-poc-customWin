build_vm = {
  size_sku            = "Standard_D2s_v3"
  os_disk_size        = 128
  os_type             = "Windows"
  image_offer         = "Windows-10"
  image_publisher     = "microsoftwindowsdesktop"
  image_sku           = "win10-22h2-avd-g2",
  resource_group      = "rg-avd-images-usgovvirginia"
  cloud_environment   = "USGovernment"  
}

compute_gallery = {
  image_name          = "win10-defualt"
  resource_group      = "rg-avd-images-usgovvirginia"
  gallery_name        = "cgavdimagegallery"
  replication_regions = ["usgovvirginia"]  
}

env = {
  az_region = "usgovvirginia"
  allowed_ips = [
    "98.218.252.27"
  ]
}