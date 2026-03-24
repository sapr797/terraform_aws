# Домашнее задание к занятию «Организация сети» + «Вычислительные мощности. Балансировщики нагрузки»

## Обязательная часть: Yandex Cloud

### Цель
Создать изолированную сетевую инфраструктуру в Yandex Cloud:
- VPC с публичной и приватной подсетями.
- NAT-инстанс для доступа приватных ресурсов в интернет.
- Виртуальные машины для проверки связности.
- Бакет Object Storage с картинкой, доступной из интернета.
- Группу ВМ на базе LAMP с веб-страницей, содержащей ссылку на картинку из бакета.
- Сетевой балансировщик нагрузки (L4) для распределения трафика между ВМ группы.

### Используемые ресурсы Terraform
- [yandex_vpc_network](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_network)
- [yandex_vpc_subnet](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_subnet)
- [yandex_vpc_route_table](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_route_table)
- [yandex_compute_instance](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance)
- [yandex_compute_instance_group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance_group)
- [yandex_storage_bucket](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/storage_bucket)
- [yandex_storage_object](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/storage_object)
- [yandex_lb_network_load_balancer](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer)
- [yandex_lb_target_group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_target_group)

### Предварительные требования
- Установленный Terraform (>= 1.0)
- Аккаунт Yandex Cloud с [зарегистрированным](https://cloud.yandex.ru/) и [авторизованным](https://cloud.yandex.ru/docs/iam/operations/authorized-key) доступом
- Настроенные переменные окружения:

```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID="ваш_cloud_id"
export YC_FOLDER_ID="ваша_folder_id"
export YC_ZONE="ru-central1-a"
export SSH_PUBLIC_KEY_PATH="~/.ssh/id_rsa.pub"
Структура конфигурации
Файлы Terraform:

variables.tf – объявление переменных
terraform.tfvars – значения переменных (не загружается в репозиторий)
main.tf – все ресурсы (VPC, подсети, NAT, ВМ, бакет, группа, балансировщик)

Применение конфигурации
terraform init
terraform plan
terraform apply

Результаты
1. Сеть и базовые ВМ
VPC main-vpc с подсетями public (192.168.10.0/24) и private (192.168.20.0/24)
NAT-инстанс с IP 192.168.10.254
Публичная ВМ public-vm с внешним IP: (вывод terraform output public_vm_external_ip)
Приватная ВМ private-vm с внутренним IP: (вывод terraform output private_vm_internal_ip)

Скриншот подключения к публичной ВМ и проверки интернета:
рис.000, рис.001, рис.002 

Скриншот подключения к приватной ВМ через публичную и проверки интернета:
рис.003, рис.005,

2. Бакет Object Storage и картинка
Бакет [ваш_бакет] создан, картинка picture.jpg загружена и доступна по ссылке:
рис.007, рис.008,

Скриншот открытой картинки в браузере:
рис.009

3. Группа ВМ с LAMP и балансировщик
Группа lamp-group из двух ВМ в публичной подсети, каждая с установленным веб-сервером и веб-страницей, содержащей ссылку на картинку из бакета.

Сетевой балансировщик lamp-lb слушает порт 80 и распределяет трафик между ВМ группы.

Скриншот веб-страницы, открытой через балансировщик:
рис.009

4. Проверка отказоустойчивости
После удаления одной из ВМ группы балансировщик автоматически исключил её из обработки, а группа создала новую ВМ. Веб-сайт оставался доступным.

Скриншот логов балансировщика после удаления ВМ:
рис.009

Дополнительная часть: AWS (не выполнена из-за санкционных ограничений)
Для выполнения задания в AWS был подготовлен Terraform-код (файлы main_aws.tf, variables_aws.tf), но из-за санкций, введённых в отношении Российской Федерации, регистрация нового аккаунта в AWS и получение ключей доступа оказались невозможны. Практическое развёртывание инфраструктуры в AWS не производилось.

Выводы
Инфраструктура в Yandex Cloud полностью соответствует требованиям задания:

Создана изолированная сеть с NAT для доступа в интернет из приватной подсети.

Настроен бакет Object Storage с публичным доступом к файлу.

Развёрнута группа ВМ с LAMP и веб-страницей, использующей картинку из бакета.

Подключён сетевой балансировщик, обеспечивающий отказоустойчивость и распределение нагрузки.

