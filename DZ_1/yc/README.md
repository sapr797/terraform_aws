# Домашнее задание к занятию «Организация сети»

## Обязательная часть: Yandex Cloud

### Цель
Создать изолированную сетевую инфраструктуру в Yandex Cloud:
- VPC с публичной и приватной подсетями.
- NAT-инстанс для доступа приватных ресурсов в интернет.
- Виртуальные машины для проверки связности.

### Предварительные требования
- Установленный [Terraform](https://www.terraform.io/downloads) (версия >= 1.0).
- Аккаунт Yandex Cloud, [зарегистрированный](https://cloud.yandex.ru/) и [авторизованный](https://cloud.yandex.ru/docs/iam/operations/authorized-key).
- Настроенные переменные окружения для провайдера:
  ```
  export YC_TOKEN=$(yc iam create-token)   # или используйте IAM-токен
  export YC_CLOUD_ID="ваш_cloud_id"
  export YC_FOLDER_ID="ваша_folder_id"
