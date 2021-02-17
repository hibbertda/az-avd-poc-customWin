variable "rgLocation" {
    type = string
}

variable "rgName" {
    type = string
}

variable "env" {
    type = map
}

# Lifetime for WVD hostpool registration key (max 30days)
variable "registrationKeyLifetime" {
    type = number
    default = 12
}