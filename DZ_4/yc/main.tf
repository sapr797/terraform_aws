terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Используем существующую сеть (предполагаем, что сеть main-vpc уже есть)
resource "yandex_vpc_network" "main" {
  name = "main-vpc"
}

# Публичные подсети (в трёх рабочих зонах)
resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}

resource "yandex_vpc_subnet" "public_d" {
  name           = "public-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.12.0/24"]
}

# Приватные подсети для MySQL (в трёх рабочих зонах)
resource "yandex_vpc_subnet" "private_mysql_a" {
  name           = "private-mysql-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.30.0/24"]
  route_table_id = yandex_vpc_route_table.private_route.id
}

resource "yandex_vpc_subnet" "private_mysql_b" {
  name           = "private-mysql-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.40.0/24"]
  route_table_id = yandex_vpc_route_table.private_route.id
}

resource "yandex_vpc_subnet" "private_mysql_d" {
  name           = "private-mysql-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.50.0/24"]
  route_table_id = yandex_vpc_route_table.private_route.id
}

# Таблица маршрутов для приватных подсетей (через NAT)
resource "yandex_vpc_route_table" "private_route" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat.network_interface.0.ip_address
  }
}

# Привязка таблицы маршрутов к приватным подсетям
#resource "yandex_vpc_subnet" "private_mysql_a_route" {
  #subnet_id      = yandex_vpc_subnet.private_mysql_a.id
  #route_table_id = yandex_vpc_route_table.private_route.id
#}
#resource "yandex_vpc_subnet" "private_mysql_b_route" {
  #subnet_id      = yandex_vpc_subnet.private_mysql_b.id
  #route_table_id = yandex_vpc_route_table.private_route.id
#}
#resource "yandex_vpc_subnet" "private_mysql_d_route" {
  #subnet_id      = yandex_vpc_subnet.private_mysql_d.id
  #route_table_id = yandex_vpc_route_table.private_route.id
#}

# NAT-инстанс (в публичной подсети зоны a)
resource "yandex_compute_instance" "nat" {
  name        = "nat-instance"
  platform_id = "standard-v2"
  zone        = "ru-central1-a"
  allow_stopping_for_update = true

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public_a.id
    ip_address = "192.168.10.254"
    nat        = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}
