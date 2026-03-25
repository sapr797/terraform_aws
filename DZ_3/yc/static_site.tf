# Бакет для статического сайта (уже есть)
resource "yandex_storage_bucket" "site" {
  bucket    = var.site_bucket_name
  folder_id = var.yc_folder_id
  acl       = "public-read"

  website {
    index_document = "index.html"
  }
}

# Загрузка картинки в бакет сайта
resource "yandex_storage_object" "site_image" {
  bucket = yandex_storage_bucket.site.bucket
  key    = "picture.jpg"
  source = "picture.jpg"
  acl    = "public-read"
}

# Загрузка index.html с локальной ссылкой на картинку
resource "yandex_storage_object" "site_index" {
  bucket  = yandex_storage_bucket.site.bucket
  key     = "index.html"
  content = <<-HTML
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Статический сайт</title>
    </head>
    <body>
      <h1>Привет, это статический сайт на Yandex Cloud</h1>
      <img src="picture.jpg" alt="Картинка">
    </body>
    </html>
  HTML
  acl          = "public-read"
  content_type = "text/html; charset=utf-8"
}

output "site_url" {
  value = "http://${yandex_storage_bucket.site.bucket}.website.yandexcloud.net"
}
