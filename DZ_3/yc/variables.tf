variable "yc_token" {
  description = "Yandex Cloud IAM token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "yc_zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "bucket_name" {
  description = "Name of the bucket for images"
  type        = string
  default     = "sapr797-images"
}

variable "site_bucket_name" {
  description = "Name of the bucket for static website"
  type        = string
  default     = "sapr797-site"
}
