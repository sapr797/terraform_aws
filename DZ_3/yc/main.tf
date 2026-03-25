terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">= 0.130.0"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yc_token
  #service_account_key_file = "key.json"
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Сеть VPC
resource "yandex_vpc_network" "main" {
  name = "main-vpc"
}

# Публичная подсеть
resource "yandex_vpc_subnet" "public" {
  name           = "public"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

# Таблица маршрутов для приватной подсети
resource "yandex_vpc_route_table" "private_route" {
  name       = "private-route-table"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat.network_interface.0.ip_address
  }
}

# Приватная подсеть с привязкой таблицы маршрутов
resource "yandex_vpc_subnet" "private" {
  name           = "private"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_route.id
}

# NAT-инстанс (публичная подсеть, фиксированный IP 192.168.10.254)
resource "yandex_compute_instance" "nat" {
  name        = "nat-instance"
  platform_id = "standard-v2"
  zone        = var.yc_zone

  resources {
    cores  = 2
    memory = 2
  }
 boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"  # образ NAT instance
      size     = 10
    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.public.id
    ip_address = "192.168.10.254"
    nat        = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# Публичная ВМ с доступом в интернет
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  platform_id = "standard-v2"
  zone        = var.yc_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8j702km20muql1rdmj"  # Ubuntu 20.04 LTS (актуальный ID)
      size     = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.public.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# Приватная ВМ (без публичного IP)
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  platform_id = "standard-v2"
  zone        = var.yc_zone

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8j702km20muql1rdmj"  # Ubuntu 20.04 LTS
      size     = 10
    } 
network_interface {
    subnet_id = yandex_vpc_subnet.private.id
    nat       = false
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# Вывод информации для подключения
output "public_vm_external_ip" {
  value = yandex_compute_instance.public_vm.network_interface.0.nat_ip_address
}

output "private_vm_internal_ip" {
  value = yandex_compute_instance.private_vm.network_interface.0.ip_address
}

output "nat_instance_internal_ip" {
  value = yandex_compute_instance.nat.network_interface.0.ip_address
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "main-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.10.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.aws_az
  tags = { Name = "public-subnet" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "main-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-route-table" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
