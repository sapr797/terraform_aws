# Получаем список IP существующих ВМ в группе (можно через data source, но проще перечислить)
# Для примера используем IP, которые вы получили ранее. Подставьте реальные внутренние IP ваших ВМ в группе.
# В вашей группе ВМ внутренние IP, вероятно, из подсети 192.168.10.0/24.
# Узнать их можно через консоль или командой:
# yc compute instance-group list-instances lamp-group

resource "yandex_alb_target_group" "lamp_alb_tg" {
  name = "lamp-alb-tg"

  target {
    subnet_id = yandex_vpc_subnet.public.id
    ip_address = "192.168.10.14"   # замените на реальный IP одной из ВМ в группе
  }
  target {
    subnet_id = yandex_vpc_subnet.public.id
    ip_address = "192.168.10.15"   # замените на реальный IP другой ВМ
  }
}

resource "yandex_alb_backend_group" "lamp_backend" {
  name = "lamp-backend"

  http_backend {
    name             = "http-backend"
    port             = 80
    target_group_ids = [yandex_alb_target_group.lamp_alb_tg.id]
    healthcheck {
      timeout             = "5s"
      interval            = "10s"
      healthy_threshold   = 3
      unhealthy_threshold = 3
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "lamp_router" {
  name = "lamp-router"
}

resource "yandex_alb_virtual_host" "lamp_vhost" {
  name           = "lamp-vhost"
  http_router_id = yandex_alb_http_router.lamp_router.id

  route {
    name = "default-route"
    http_route {
      action {
        backend_group_id = yandex_alb_backend_group.lamp_backend.id
      }
    }
  }
}

resource "yandex_vpc_address" "alb_address" {
  name = "alb-address"
  external_ipv4_address {
    zone_id = var.yc_zone
  }
}

resource "yandex_alb_load_balancer" "lamp_alb" {
  name        = "lamp-alb"
  network_id  = yandex_vpc_network.main.id
  description = "Application Load Balancer for lamp group"

  allocation_policy {
    location {
      zone_id   = var.yc_zone
      subnet_id = yandex_vpc_subnet.public.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {
          address = yandex_vpc_address.alb_address.external_ipv4_address[0].address
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.lamp_router.id
      }
    }
  }
}

output "alb_external_ip" {
  value = yandex_alb_load_balancer.lamp_alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

