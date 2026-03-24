# ===================================================================
# group.tf – группа ВМ с LAMP, балансировщик и сервисный аккаунт
# ===================================================================

# ---- Сервисный аккаунт для управления группой ВМ ----
resource "yandex_iam_service_account" "sa" {
  name = "instance-group-sa"
}

# Назначение роли editor на каталог для сервисного аккаунта
resource "yandex_resourcemanager_folder_iam_member" "alb_editor" {
  folder_id = var.yc_folder_id
  role      = "alb_editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# ---- Целевая группа (пустая, заполнится через группу ВМ) ----
#resource "yandex_lb_target_group" "lamp_tg" {
  #name      = "lamp-tg"
  #region_id = "ru-central1"
#}

# ---- Группа виртуальных машин с LAMP ----
resource "yandex_compute_instance_group" "lamp_group" {
  name                = "lamp-group"
  folder_id           = var.yc_folder_id
  service_account_id  = yandex_iam_service_account.sa.id
  deletion_protection = false

  instance_template {
    platform_id = "standard-v2"

    resources {
      cores  = 2
      memory = 2
    }

    boot_disk {
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"   # LAMP образ
        size     = 10
      }
    }

    network_interface {
      subnet_ids = [yandex_vpc_subnet.public.id]   # публичная подсеть
      nat       = true                           # выдаём публичный IP
    }

    metadata = {
      user-data = <<-EOF
        #!/bin/bash
        # Установка веб-страницы с ссылкой на картинку из бакета
        cat > /var/www/html/index.html <<HTML
        <html>
          <body>
            <h1>Привет! Это ВМ из группы</h1>
            <img src="https://${yandex_storage_bucket.images.bucket}.storage.yandexcloud.net/${yandex_storage_object.image.key}" alt="Картинка из бакета">
          </body>
        </html>
        HTML
        systemctl restart httpd
      EOF
    }
  }

  scale_policy {
    fixed_scale {
      size = 2   # количество ВМ в группе
    }
  }

  allocation_policy {
    zones = [var.yc_zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
  }

  health_check {
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
    tcp_options {
      port = 80
    }
  }

  # Привязка к целевой группе балансировщика
 #application_load_balancer {
    #target_group_name = yandex_alb_target_group.lamp_alb_tg.id  
 #}
}

