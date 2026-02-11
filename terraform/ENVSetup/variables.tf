variable "location" {
  type        = string
  description = "Azure Region"
}

variable "az_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group for the Compute Gallery"
}

variable "gallery_name" {
  type        = string
  description = "Name of the Azure Compute Gallery"
}

variable "gallery_description" {
  type        = string
  description = "Description for the Azure Compute Gallery"
  default     = "Azure Compute Gallery for AVD images"
}

variable "image_name" {
  type        = string
  description = "Image definition name in the gallery"
}

variable "image_os_type" {
  type        = string
  description = "OS type for the image definition"
  default     = "Windows"
}

variable "image_hyper_v_generation" {
  type        = string
  description = "Hyper-V generation for the image definition (V1 or V2)"
  default     = "V2"
}

variable "image_publisher" {
  type        = string
  description = "Custom image identifier — publisher"
}

variable "image_offer" {
  type        = string
  description = "Custom image identifier — offer"
}

variable "image_sku" {
  type        = string
  description = "Custom image identifier — SKU"
}