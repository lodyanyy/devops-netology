## 1. Регистрация доменного имени  
Зарегистрировали доменное имя lodyanyy.ru на reg.ru. Соответственно, получили доступ к личному кабинету на сйте регистратора и можем управлять доменом.  

## 2. Создание инфраструктуры  

Для реализации IaaC подхода при организации (эксплуатации) инфраструктуры написан bash-скрипт, который создаёт каталог в указанном YC облаке, сервисный аккаунт для дальнейшей работы с терраформом, сохраняет чувствительные данные в отдельный файл private.auto.tfvars вне репозитария, а также собирает и передает идентификаторы яндекс облака и каталога в конфигурационные файлы терраформа, а также автоматически создает S3 bucket в YC.
Изначально в файл private.auto.tfvars требуется сохранить только значения OAuth-токена и ID облака, в котором будем работать.

```bash
#!/usr/bin/env bash

echo "создание профиля main-profile"
yc config profile create main-profile

echo "присвоение переменной YC_TOKEN соответствующеего значения из файла private.auto.tfvars"
YC_TOKEN=$(sed 's/"//g' ~/netology/diplom/terraform/private.auto.tfvars | sed -n '1,1 s/YC_TOKEN = //p')

echo "назначение OAth-токена профилю main-profile"
yc config set token $YC_TOKEN --profile main-profile

echo "присвоение переменной YC_CLOUD_ID соответствующего значения из файла private.auto.tfvars"
YC_CLOUD_ID=$(sed 's/"//g' ~/netology/diplom/terraform/private.auto.tfvars | sed -n '2,2 s/YC_CLOUD_ID = //p')

echo "назначение ID облака профилю main-profile"
yc config set cloud-id $YC_CLOUD_ID

echo "создание каталога с именем main-folder"
yc resource-manager folder create --name main-folder --profile main-profile

echo "передача ID каталога в переменную YC_FOLDER_ID"
YC_FOLDER_ID=$(yc resource-manager folder get main-folder | sed -n '1,1 s/id: //p')
echo $YC_FOLDER_ID

echo "передадча значения переменной YC_FOLDER_ID в файл variables.tf" 
sed -i "6c\  default = \"${YC_FOLDER_ID}\"" ~/netology/diplom/terraform_S3/variables.tf
sed -i "6c\  default = \"${YC_FOLDER_ID}\"" ~/netology/diplom/terraform/variables.tf

echo "передача значения переменной YC_CLOUD_ID в файл variables.tf"
sed -i "2c\  default = \"${YC_CLOUD_ID}\"" ~/netology/diplom/terraform_S3/variables.tf
sed -i "2c\  default = \"${YC_CLOUD_ID}\"" ~/netology/diplom/terraform/variables.tf

echo "создание сервисного аккаунта с именем service-bot в каталоге main-folder"
array1=($(yc iam service-account create --folder-name main-folder --name service-bot | cut -d: -f 2 | cut -c 2-))
YC_SERVICE_ACCOUNT_ID=${array1[0]}
echo $YC_SERVICE_ACCOUNT_ID

echo "создание статического ключа доступа для сервисного аккаунта service-bot и передача его в private.auto.tfvars"
array2=($(yc iam access-key create --service-account-name service-bot --folder-id $YC_FOLDER_ID | cut -d: -f 2 | cut -c 2-))

YC_ACCESS_KEY=${array2[3]}
echo $YC_ACCESS_KEY
sed -i "3c\YC_ACCESS_KEY = \"${YC_ACCESS_KEY}\"" ~/netology/diplom/terraform/private.auto.tfvars
sed -i "1c\access_key = \"${YC_ACCESS_KEY}\"" ~/netology/diplom/terraform/backend.tfvars

YC_SECRET_KEY=${array2[4]}
echo $YC_SECRET_KEY
sed -i "4c\YC_SECRET_KEY = \"${YC_SECRET_KEY}\"" ~/netology/diplom/terraform/private.auto.tfvars
sed -i "2c\secret_key = \"${YC_SECRET_KEY}\"" ~/netology/diplom/terraform/backend.tfvars

echo "назначение сервисному аккаунту роли editor"
yc resource-manager folder add-access-binding $YC_FOLDER_ID --role editor --subject serviceAccount:$YC_SERVICE_ACCOUNT_ID

echo "создание S3 bucket в YC через terraform"
cd ~/netology/diplom/terraform_S3
terraform init
terraform workspace new stage
terraform plan -var-file ~/netology/diplom/terraform/private.auto.tfvars
terraform apply --auto-approve -var-file ~/netology/diplom/terraform/private.auto.tfvars
echo "переход в основной каталог"
cd ~/netology/diplom/terraform
terraform init -backend-config=backend.tfvars
terraform workspace new stage
terraform plan -var-file ~/netology/diplom/terraform/private.auto.tfvars
terraform apply --auto-approve -var-file ~/netology/diplom/terraform/private.auto.tfvars
```
В результате настроен workspace stage, созданы VPC в разных зонах доступности, и имеем возможность быстро создавать, а также удалять виртуальные машины и сети, выполняя лишь команды terraform apply и terraform destroy.
<details>
<summary> terraform apply -auto-approve </summary> 

```bash
ubuntu@lodyanyynote:~/netology/diplom/terraform$ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_instance.app will be created
  + resource "yandex_compute_instance" "app" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "app.lodyanyy.ru"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: ubuntu
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClS4cBn5ORuN...
            EOT
        }
      + name                      = "app"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kdq6d0p8sij7h5qe3"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 4
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.db01 will be created
  + resource "yandex_compute_instance" "db01" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "db01.lodyanyy.ru"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: ubuntu
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClS4cBn5ORuN...
            EOT
        }
      + name                      = "db01"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kdq6d0p8sij7h5qe3"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 4
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.db02 will be created
  + resource "yandex_compute_instance" "db02" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "db02.lodyanyy.ru"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: ubuntu
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClS4cBn5ORuN...
            EOT
        }
      + name                      = "db02"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kdq6d0p8sij7h5qe3"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 4
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.gitlab will be created
  + resource "yandex_compute_instance" "gitlab" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "gitlab.lodyanyy.ru"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: ubuntu
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClS4cBn5ORuN...
            EOT
        }
      + name                      = "gitlab"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kdq6d0p8sij7h5qe3"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 4
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.lodyanyy will be created
  + resource "yandex_compute_instance" "lodyanyy" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "lodyanyy.ru"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: ubuntu
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClS4cBn5ORuN...
            EOT
        }
      + name                      = "lodyanyy"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kdq6d0p8sij7h5qe3"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = true
          + nat_ip_address     = "51.250.0.213"
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 2
          + memory        = 2
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.monitoring will be created
  + resource "yandex_compute_instance" "monitoring" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "monitoring.lodyanyy.ru"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: ubuntu
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClS4cBn5ORuN...
            EOT
        }
      + name                      = "monitoring"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kdq6d0p8sij7h5qe3"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 4
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_compute_instance.runner will be created
  + resource "yandex_compute_instance" "runner" {
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = "runner.lodyanyy.ru"
      + id                        = (known after apply)
      + metadata                  = {
          + "user-data" = <<-EOT
                #cloud-config
                users:
                  - name: ubuntu
                    groups: sudo
                    shell: /bin/bash
                    sudo: ['ALL=(ALL) NOPASSWD:ALL']
                    ssh_authorized_keys:
                      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQClS4cBn5ORuN...
            EOT
        }
      + name                      = "runner"
      + network_acceleration_type = "standard"
      + platform_id               = "standard-v1"
      + service_account_id        = (known after apply)
      + status                    = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete = true
          + device_name = (known after apply)
          + disk_id     = (known after apply)
          + mode        = (known after apply)

          + initialize_params {
              + block_size  = (known after apply)
              + description = (known after apply)
              + image_id    = "fd8kdq6d0p8sij7h5qe3"
              + name        = (known after apply)
              + size        = 10
              + snapshot_id = (known after apply)
              + type        = "network-hdd"
            }
        }

      + network_interface {
          + index              = (known after apply)
          + ip_address         = (known after apply)
          + ipv4               = true
          + ipv6               = (known after apply)
          + ipv6_address       = (known after apply)
          + mac_address        = (known after apply)
          + nat                = false
          + nat_ip_address     = (known after apply)
          + nat_ip_version     = (known after apply)
          + security_group_ids = (known after apply)
          + subnet_id          = (known after apply)
        }

      + placement_policy {
          + host_affinity_rules = (known after apply)
          + placement_group_id  = (known after apply)
        }

      + resources {
          + core_fraction = 100
          + cores         = 4
          + memory        = 4
        }

      + scheduling_policy {
          + preemptible = (known after apply)
        }
    }

  # yandex_vpc_network.network-1 will be created
  + resource "yandex_vpc_network" "network-1" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "network1"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet-1 will be created
  + resource "yandex_vpc_subnet" "subnet-1" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet1"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.10.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

  # yandex_vpc_subnet.subnet-2 will be created
  + resource "yandex_vpc_subnet" "subnet-2" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet2"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.11.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

Plan: 10 to add, 0 to change, 0 to destroy.
yandex_vpc_network.network-1: Creating...
yandex_vpc_network.network-1: Creation complete after 4s [id=enp786h8l2mmvqp48f82]
yandex_vpc_subnet.subnet-2: Creating...
yandex_vpc_subnet.subnet-1: Creating...
yandex_vpc_subnet.subnet-2: Creation complete after 1s [id=e2lcmsg4vpg2t9sssrq8]
yandex_vpc_subnet.subnet-1: Creation complete after 2s [id=e9b94q5duoe5u9hhkcl5]
yandex_compute_instance.db01: Creating...
yandex_compute_instance.runner: Creating...
yandex_compute_instance.monitoring: Creating...
yandex_compute_instance.app: Creating...
yandex_compute_instance.db02: Creating...
yandex_compute_instance.gitlab: Creating...
yandex_compute_instance.lodyanyy: Creating...
yandex_compute_instance.db01: Still creating... [10s elapsed]
yandex_compute_instance.runner: Still creating... [10s elapsed]
yandex_compute_instance.monitoring: Still creating... [10s elapsed]
yandex_compute_instance.db02: Still creating... [10s elapsed]
yandex_compute_instance.gitlab: Still creating... [10s elapsed]
yandex_compute_instance.app: Still creating... [10s elapsed]
yandex_compute_instance.lodyanyy: Still creating... [10s elapsed]
yandex_compute_instance.db01: Still creating... [20s elapsed]
yandex_compute_instance.runner: Still creating... [20s elapsed]
yandex_compute_instance.db02: Still creating... [20s elapsed]
yandex_compute_instance.monitoring: Still creating... [20s elapsed]
yandex_compute_instance.gitlab: Still creating... [20s elapsed]
yandex_compute_instance.app: Still creating... [20s elapsed]
yandex_compute_instance.lodyanyy: Still creating... [20s elapsed]
yandex_compute_instance.monitoring: Creation complete after 25s [id=fhmg9vjooau4897gvc0k]
yandex_compute_instance.app: Creation complete after 25s [id=fhmug1mn2u62eg7tka96]
yandex_compute_instance.gitlab: Creation complete after 25s [id=fhmufc3qavqrje01ibm8]
yandex_compute_instance.db01: Creation complete after 27s [id=fhm8mrhns4gemfsikjja]
yandex_compute_instance.lodyanyy: Creation complete after 28s [id=fhmq8jdkv49g3q0jbkb7]
yandex_compute_instance.db02: Creation complete after 29s [id=fhmevrcr5q5qmrq676u3]
yandex_compute_instance.runner: Still creating... [30s elapsed]
yandex_compute_instance.runner: Creation complete after 30s [id=fhmthrr1du8en0ld1vg5]

```  
</details>

## 3. Установка Nginx И LetsEncrypt
