# Бакет Object Storage
resource "yandex_storage_bucket" "images" {
  bucket = var.bucket_name
  acl    = "public-read"   # делаем файлы доступными из интернета
}

# Загрузка файла картинки (предположим, что файл picture.jpg находится в локальной папке)
resource "yandex_storage_object" "image" {
  bucket = yandex_storage_bucket.images.bucket
  key    = "picture.jpg"
  source = "picture.jpg"   # путь к локальному файлу
  acl    = "public-read"
}

# Вывод URL картинки
output "image_url" {
  value = "https://${yandex_storage_bucket.images.bucket}.storage.yandexcloud.net/${yandex_storage_object.image.key}"
}
