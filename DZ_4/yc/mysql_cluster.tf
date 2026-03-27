resource "yandex_mdb_mysql_cluster" "mysql" {
  name                = var.db_cluster_name
  environment         = "PRESTABLE"
  network_id          = yandex_vpc_network.main.id
  version             = "8.0"
  deletion_protection = false

  resources {
    resource_preset_id = "s2.micro"        # Intel Broadwell, 2 vCPU
    disk_type_id       = "network-ssd"
    disk_size          = 20
  }

  backup_window_start {
    hours   = 23
    minutes = 59
  }

  # Хосты в трёх зонах (a, b, d)
  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.private_mysql_a.id
  }
  host {
    zone      = "ru-central1-b"
    subnet_id = yandex_vpc_subnet.private_mysql_b.id
  }
  host {
    zone      = "ru-central1-d"
    subnet_id = yandex_vpc_subnet.private_mysql_d.id
  }

  database {
    name = var.db_name
  }
  user {
    name     = var.db_user
    password = var.db_password
    permission {
      database_name = var.db_name
      roles         = ["ALL"]
    }
  }
}

output "mysql_fqdn" {
  value = yandex_mdb_mysql_cluster.mysql.host[*].fqdn
}
