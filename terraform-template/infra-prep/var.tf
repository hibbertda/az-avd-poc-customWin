variable "env" {
    type = map
    default = {
        "envName"   = "wvddemo"
        "region"    = "centralus"
    }
}

variable "adds-join-username" {
    type = string
}

variable "adds-join-password" {
    type = string
}

variable "vm-admin-password" {
    type = string
}