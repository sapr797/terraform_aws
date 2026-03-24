resource "yandex_lb_network_load_balancer" "lamp_lb" {
  name = "lamp-lb"
  type = "external"

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.lamp_group.load_balancer[0].target_group_id
    healthcheck {
      name                = "http"
      interval            = 2
      timeout             = 1
      unhealthy_threshold = 2
      healthy_threshold   = 2
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
output "lb_external_ip" {
  value = one(yandex_lb_network_load_balancer.lamp_lb.listener[*].external_address_spec[*].address)
}
