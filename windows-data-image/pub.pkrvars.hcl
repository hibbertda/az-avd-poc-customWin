build_vm = {
  size_sku            = "Standard_D2s_v3"
  os_disk_size        = 128
  os_type             = "Windows"
  image_offer         = "Windows-11"
  image_publisher     = "microsoftwindowsdesktop"
  image_sku           = "win11-23h2-avd",
  resource_group      = "rg-avd-images-centralus"
  cloud_environment   = "Public"  
}

compute_gallery = {
  image_name          = "win11-data"
  resource_group      = "rg-avd-images-centralus"
  gallery_name        = "cgavdimagegallery"
  replication_regions = ["centralus"]  
}

env = {
  az_region = "centralus"
  allowed_ips = [
    "73.250.80.74"
  ]
}