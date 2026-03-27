# Сервис-аккаунт для Kubernetes
resource "yandex_iam_service_account" "k8s" {
  name = "k8s-sa"
}

# Роли для сервис-аккаунта
resource "yandex_resourcemanager_folder_iam_member" "k8s_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_cluster_agent" {
  folder_id = var.yc_folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Добавим роль vpc.user для доступа к сети
resource "yandex_resourcemanager_folder_iam_member" "k8s_vpc_user" {
  folder_id = var.yc_folder_id
  role      = "vpc.user"
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Региональный кластер Kubernetes
resource "yandex_kubernetes_cluster" "k8s" {
  name        = var.k8s_cluster_name
  network_id  = yandex_vpc_network.main.id

  master {
    regional {
      region = "ru-central1"
      location {
        zone      = "ru-central1-a"
        subnet_id = yandex_vpc_subnet.public_a.id
      }
      location {
        zone      = "ru-central1-b"
        subnet_id = yandex_vpc_subnet.public_b.id
      }
      location {
        zone      = "ru-central1-d"
        subnet_id = yandex_vpc_subnet.public_d.id
      }
    }
    version   = "1.31"
    public_ip = true
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id
}

# Группа узлов
resource "yandex_kubernetes_node_group" "nodes" {
  name        = var.k8s_node_group_name
  cluster_id  = yandex_kubernetes_cluster.k8s.id
  version     = "1.31"

  instance_template {
    platform_id = "standard-v2"
    resources {
      cores  = 2
      memory = 4
    }
    boot_disk {
      type = "network-ssd"
      size = 30
    }
    network_interface {
      subnet_ids = [
        yandex_vpc_subnet.public_a.id,
        yandex_vpc_subnet.public_b.id,
        yandex_vpc_subnet.public_d.id
      ]
      nat = true
    }
    metadata = {
      ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    location {
      zone = "ru-central1-a"
    }
    location {
      zone = "ru-central1-b"
    }
    location {
      zone = "ru-central1-d"
    }
  }
}

output "k8s_cluster_id" {
  value = yandex_kubernetes_cluster.k8s.id
}

output "k8s_cluster_master_external_ip" {
  value = yandex_kubernetes_cluster.k8s.master[0].external_v4_address
}
