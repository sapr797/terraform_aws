resource "yandex_kms_symmetric_key" "bucket_key" {
  name              = "bucket-encryption-key"
  description       = "Key for encrypting Object Storage bucket"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
}

resource "yandex_storage_bucket" "images" {
  bucket    = var.bucket_name
  folder_id = var.yc_folder_id
  force_destroy = true
  acl       = "public-read"    # публичный доступ к бакету (предупреждение можно игнорировать)

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "yandex_storage_object" "image" {
  bucket = yandex_storage_bucket.images.bucket
  key    = "picture.jpg"
  source = "picture.jpg"
  acl    = "public-read"
}

output "image_url" {
  value = "https://${yandex_storage_bucket.images.bucket}.storage.yandexcloud.net/${yandex_storage_object.image.key}"
}
