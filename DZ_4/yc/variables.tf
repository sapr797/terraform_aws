variable "yc_token" {
  description = "Yandex Cloud IAM token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "yc_zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "/home/alexlinux/.ssh/id_ed25519_new.pub"
}

variable "db_cluster_name" {
  default = "mysql-cluster"
}
variable "db_name" {
  default = "netology_db"
}
variable "db_user" {
  default = "netology_user"
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "k8s_cluster_name" {
  default = "k8s-cluster"
}
variable "k8s_node_group_name" {
  default = "k8s-node-group"
}
