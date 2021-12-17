
variable "env" {
  type = map
  default = {
      "name" = "win10image"
      "region" = "centralUS"
  }
}

variable "network" {
  type = map
  default = {
    "ipv4Network" = "10.20.0.0/16",
    "allowRemoteAccess" = "98.218.252.27"
  }
}

variable "subnets" {
  type = map
  default = {
    "vm" = 0
  }
}