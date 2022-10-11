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

Видим созданные виртуальные машины в Yandex Cloud  

![](https://user-images.githubusercontent.com/87534423/195144494-34a43de2-eaf0-41a3-bee5-d65854e1e5af.jpg)



## 3. Установка Nginx И LetsEncrypt

<details>
<summary> ansible-playbook main.yml -i hosts </summary> 

```bash
ubuntu@lodyanyynote:~/netology/diplom/ansible$ ansible-playbook main.yml -i hosts
[DEPRECATION WARNING]: "include" is deprecated, use include_tasks/import_tasks instead. This feature will be removed in version 2.16. Deprecation warnings can be 
disabled by setting deprecation_warnings=False in ansible.cfg.

PLAY [front] **********************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************
ok: [lodyanyy.ru]

TASK [update : Update apt repo and cache on all Debian/Ubuntu boxes] **************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : python-simplejson] **************************************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Upgrade system] *****************************************************************************************************************************
ok: [lodyanyy.ru]

TASK [nginx_letsencrypt : Install nginx] ******************************************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : install letsencrypt] ************************************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : create letsencrypt directory] ***************************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Remove default nginx config] ****************************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Install system nginx config] ****************************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Install nginx site for letsencrypt requests] ************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Reload nginx to activate letsencrypt site] **************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Create letsencrypt certificate front] *******************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Create letsencrypt certificate gitlab] ******************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Create letsencrypt certificate grafana] *****************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Create letsencrypt certificate prometheus] **************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Create letsencrypt certificate alertmanager] ************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Generate dhparams] **************************************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Install nginx site for specified site] ******************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Reload nginx to activate specified site] ****************************************************************************************************
changed: [lodyanyy.ru]

TASK [nginx_letsencrypt : Add letsencrypt cronjob for cert renewal] ***************************************************************************************************
changed: [lodyanyy.ru]

TASK [proxy : install privoxy] ****************************************************************************************************************************************
changed: [lodyanyy.ru]

TASK [proxy : configure privoxy] **************************************************************************************************************************************
changed: [lodyanyy.ru]

TASK [proxy : start privoxy] ******************************************************************************************************************************************
ok: [lodyanyy.ru]

TASK [node_exporter : Assert usage of systemd as an init system] ******************************************************************************************************
ok: [lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [node_exporter : Get systemd version] ****************************************************************************************************************************
ok: [lodyanyy.ru]

TASK [node_exporter : Set systemd version fact] ***********************************************************************************************************************
ok: [lodyanyy.ru]

TASK [node_exporter : Naive assertion of proper listen address] *******************************************************************************************************
ok: [lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [node_exporter : Assert collectors are not both disabled and enabled at the same time] ***************************************************************************

TASK [node_exporter : Assert that TLS key and cert path are set] ******************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Check existence of TLS cert file] ***************************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Check existence of TLS key file] ****************************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Assert that TLS key and cert are present] *******************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Check if node_exporter is installed] ************************************************************************************************************
ok: [lodyanyy.ru]

TASK [node_exporter : Gather currently installed node_exporter version (if any)] **************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Get latest release] *****************************************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Set node_exporter version to {{ _latest_release.json.tag_name[1:] }}] ***************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Get checksum list from github] ******************************************************************************************************************
ok: [lodyanyy.ru -> localhost]

TASK [node_exporter : Get checksum for amd64 architecture] ************************************************************************************************************
skipping: [lodyanyy.ru] => (item=3919266f1dbad5f7e5ce7b4207057fc253a8322f570607cc0f3e73f4a53338e3  node_exporter-1.1.2.darwin-amd64.tar.gz) 
skipping: [lodyanyy.ru] => (item=5b0195e203dedd3a8973cd1894a55097554a4af6d8f4f0614c2c67d6670ea8ae  node_exporter-1.1.2.linux-386.tar.gz) 
ok: [lodyanyy.ru -> localhost] => (item=8c1f6a317457a658e0ae68ad710f6b4098db2cad10204649b51e3c043aa3e70d  node_exporter-1.1.2.linux-amd64.tar.gz)
skipping: [lodyanyy.ru] => (item=eb5e7d16f18bb3272d0d832986fc8ac6cb0b6c42d487c94e15dabb10feae8e04  node_exporter-1.1.2.linux-arm64.tar.gz) 
skipping: [lodyanyy.ru] => (item=41892e451e80160491a1cc7bbe6bccd6cb842ae8340e1bc6e32f72cefb1aee80  node_exporter-1.1.2.linux-armv5.tar.gz) 
skipping: [lodyanyy.ru] => (item=1cc1bf4cacb84d6c228d9ce8045b5b00b73afd954046f7b2add428a04d14daee  node_exporter-1.1.2.linux-armv6.tar.gz) 
skipping: [lodyanyy.ru] => (item=a9fe816eb7b976b1587d6d654c437f7d78349f70686fa22ae33e94fe84281af2  node_exporter-1.1.2.linux-armv7.tar.gz) 
skipping: [lodyanyy.ru] => (item=a99ab2cdc62db25ff01d184e21ad433e3949cd791fc2c80b6bacc6b90d5a62c2  node_exporter-1.1.2.linux-mips.tar.gz) 
skipping: [lodyanyy.ru] => (item=22d9c2a5363502c79e0645ba02eafd9561b33d1e0e819ce4df3fcf7dc96e3792  node_exporter-1.1.2.linux-mips64.tar.gz) 
skipping: [lodyanyy.ru] => (item=a66b70690c3c4fff953905a041c74834f96be85a806e74a1cc925e607ef50a26  node_exporter-1.1.2.linux-mips64le.tar.gz) 
skipping: [lodyanyy.ru] => (item=f7fba791cbc758b021d0e9a2400c82d1f29337e568ab00edc84b053ca467ea3c  node_exporter-1.1.2.linux-mipsle.tar.gz) 
skipping: [lodyanyy.ru] => (item=294c0b05dff4f368512449de7268e3f06de679a9343e9885044adc702865080b  node_exporter-1.1.2.linux-ppc64.tar.gz) 
skipping: [lodyanyy.ru] => (item=d1d201b16d757980db654bb9e448ab0c81ca4c2715243c3fa4305bef5967bd41  node_exporter-1.1.2.linux-ppc64le.tar.gz) 
skipping: [lodyanyy.ru] => (item=6007420f425d08626c05de2dbe0e8bb785a16bba1b02c01cb06d37d7fab3bc97  node_exporter-1.1.2.linux-s390x.tar.gz) 
skipping: [lodyanyy.ru] => (item=0596e9c1cc358e6fcc60cb83f0d1ba9a37ccee11eca035429c9791c0beb04389  node_exporter-1.1.2.netbsd-386.tar.gz) 
skipping: [lodyanyy.ru] => (item=46c964efd336f0e35f62c739ce9edf5409911e7652604e411c9b684eb9c48386  node_exporter-1.1.2.netbsd-amd64.tar.gz) 
skipping: [lodyanyy.ru] => (item=d81f86f57a4ed167a4062aa47f8a70b35c146c86bc8e40924c9d1fc3644ec8e6  node_exporter-1.1.2.openbsd-amd64.tar.gz) 

TASK [node_exporter : Create the node_exporter group] *****************************************************************************************************************
changed: [lodyanyy.ru]

TASK [node_exporter : Create the node_exporter user] ******************************************************************************************************************
changed: [lodyanyy.ru]

TASK [node_exporter : Download node_exporter binary to local folder] **************************************************************************************************
changed: [lodyanyy.ru -> localhost]

TASK [node_exporter : Unpack node_exporter binary] ********************************************************************************************************************
changed: [lodyanyy.ru -> localhost]

TASK [node_exporter : Propagate node_exporter binaries] ***************************************************************************************************************
changed: [lodyanyy.ru]

TASK [node_exporter : propagate locally distributed node_exporter binary] *********************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Install selinux python packages [RHEL]] *********************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Install selinux python packages [Fedora]] *******************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Install selinux python packages [clearlinux]] ***************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Copy the node_exporter systemd service file] ****************************************************************************************************
changed: [lodyanyy.ru]

TASK [node_exporter : Create node_exporter config directory] **********************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Copy the node_exporter config file] *************************************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Create textfile collector dir] ******************************************************************************************************************
changed: [lodyanyy.ru]

TASK [node_exporter : Allow node_exporter port in SELinux on RedHat OS family] ****************************************************************************************
skipping: [lodyanyy.ru]

TASK [node_exporter : Ensure Node Exporter is enabled on boot] ********************************************************************************************************
changed: [lodyanyy.ru]

RUNNING HANDLER [proxy : restart privoxy] *****************************************************************************************************************************
changed: [lodyanyy.ru]

RUNNING HANDLER [node_exporter : restart node_exporter] ***************************************************************************************************************
changed: [lodyanyy.ru]

PLAY RECAP ************************************************************************************************************************************************************
lodyanyy.ru                : ok=40   changed=30   unreachable=0    failed=0    skipped=15   rescued=0    ignored=0
```  
 </details>
 
![LE](https://user-images.githubusercontent.com/87534423/195150894-9ea0c667-f6ce-4aeb-9098-a7b4cd1bedaa.jpg)  

## 4. Установка кластера MySQL  

<details>
<summary> ansible-playbook mysql.yml -i hosts </summary>

```bash
ubuntu@lodyanyynote:~/netology/diplom/ansible$ ansible-playbook mysql.yml -i hosts

PLAY [mysql] **********************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************
ok: [db02.lodyanyy.ru]
ok: [db01.lodyanyy.ru]

TASK [update : Update apt repo and cache on all Debian/Ubuntu boxes] **************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : include_tasks] ******************************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/mysql/tasks/variables.yml for db01.lodyanyy.ru, db02.lodyanyy.ru

TASK [mysql : Include OS-specific variables.] *************************************************************************************************************************
ok: [db01.lodyanyy.ru] => (item=/home/ubuntu/netology/diplom/ansible/roles/mysql/vars/Debian.yml)
ok: [db02.lodyanyy.ru] => (item=/home/ubuntu/netology/diplom/ansible/roles/mysql/vars/Debian.yml)

TASK [mysql : Define mysql_packages.] *********************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_daemon.] ***********************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_slow_query_log_file.] **********************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_log_error.] ********************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_syslog_tag.] *******************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_pid_file.] *********************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_config_file.] ******************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_config_include_dir.] ***********************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_socket.] ***********************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Define mysql_supports_innodb_large_prefix.] *************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : include_tasks] ******************************************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : include_tasks] ******************************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/mysql/tasks/setup-Debian.yml for db01.lodyanyy.ru, db02.lodyanyy.ru

TASK [mysql : Check if MySQL is already installed.] *******************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Update apt cache if MySQL is not yet installed.] ********************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : Ensure MySQL Python libraries are installed.] ***********************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Ensure MySQL packages are installed.] *******************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Ensure MySQL is stopped after initial install.] *********************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : Delete innodb log files created by apt package after initial install.] **********************************************************************************
skipping: [db01.lodyanyy.ru] => (item=ib_logfile0) 
skipping: [db01.lodyanyy.ru] => (item=ib_logfile1) 
skipping: [db02.lodyanyy.ru] => (item=ib_logfile0) 
skipping: [db02.lodyanyy.ru] => (item=ib_logfile1) 

TASK [mysql : include_tasks] ******************************************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : Check if MySQL packages were installed.] ****************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : include_tasks] ******************************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/mysql/tasks/configure.yml for db01.lodyanyy.ru, db02.lodyanyy.ru

TASK [mysql : Get MySQL version.] *************************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Copy my.cnf global MySQL configuration.] ****************************************************************************************************************
ok: [db02.lodyanyy.ru]
ok: [db01.lodyanyy.ru]

TASK [mysql : Verify mysql include directory exists.] *****************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : Copy my.cnf override files into include directory.] *****************************************************************************************************

TASK [mysql : Create slow query log file (if configured).] ************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : Create datadir if it does not exist] ********************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Set ownership on slow query log file (if configured).] **************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : Create error log file (if configured).] *****************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : Set ownership on error log file (if configured).] *******************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]

TASK [mysql : Ensure MySQL is started and enabled on boot.] ***********************************************************************************************************
ok: [db02.lodyanyy.ru]
ok: [db01.lodyanyy.ru]

TASK [mysql : include_tasks] ******************************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/mysql/tasks/secure-installation.yml for db01.lodyanyy.ru, db02.lodyanyy.ru

TASK [mysql : Ensure default user is present.] ************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Copy user-my.cnf file with password credentials.] *******************************************************************************************************
ok: [db02.lodyanyy.ru]
ok: [db01.lodyanyy.ru]

TASK [mysql : Disallow root login remotely] ***************************************************************************************************************************
ok: [db02.lodyanyy.ru] => (item=DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'))
ok: [db01.lodyanyy.ru] => (item=DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'))

TASK [mysql : Get list of hosts for the root user.] *******************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Update MySQL root password for localhost root account (5.7.x).] *****************************************************************************************
changed: [db01.lodyanyy.ru] => (item=localhost)
changed: [db02.lodyanyy.ru] => (item=localhost)

TASK [mysql : Update MySQL root password for localhost root account (< 5.7.x).] ***************************************************************************************
skipping: [db01.lodyanyy.ru] => (item=localhost) 
skipping: [db02.lodyanyy.ru] => (item=localhost) 

TASK [mysql : Copy .my.cnf file with root password credentials.] ******************************************************************************************************
ok: [db02.lodyanyy.ru]
ok: [db01.lodyanyy.ru]

TASK [mysql : Get list of hosts for the anonymous user.] **************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Remove anonymous MySQL users.] **************************************************************************************************************************

TASK [mysql : Remove MySQL test database.] ****************************************************************************************************************************
ok: [db02.lodyanyy.ru]
ok: [db01.lodyanyy.ru]

TASK [mysql : include_tasks] ******************************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/mysql/tasks/databases.yml for db01.lodyanyy.ru, db02.lodyanyy.ru

TASK [mysql : Ensure MySQL databases are present.] ********************************************************************************************************************
ok: [db01.lodyanyy.ru] => (item={'name': 'wordpress', 'collation': 'utf8_general_ci', 'encoding': 'utf8', 'replicate': 1})
ok: [db02.lodyanyy.ru] => (item={'name': 'wordpress', 'collation': 'utf8_general_ci', 'encoding': 'utf8', 'replicate': 1})

TASK [mysql : include_tasks] ******************************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/mysql/tasks/users.yml for db01.lodyanyy.ru, db02.lodyanyy.ru

TASK [mysql : Ensure MySQL users are present.] ************************************************************************************************************************
ok: [db01.lodyanyy.ru] => (item=None)
ok: [db02.lodyanyy.ru] => (item=None)
ok: [db02.lodyanyy.ru] => (item=None)
changed: [db01.lodyanyy.ru] => (item=None)
ok: [db02.lodyanyy.ru]
changed: [db01.lodyanyy.ru]

TASK [mysql : include_tasks] ******************************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/mysql/tasks/replication.yml for db01.lodyanyy.ru, db02.lodyanyy.ru

TASK [mysql : Ensure replication user exists on master.] **************************************************************************************************************
skipping: [db02.lodyanyy.ru]
changed: [db01.lodyanyy.ru]

TASK [mysql : Check slave replication status.] ************************************************************************************************************************
skipping: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]

TASK [mysql : Check master replication status.] ***********************************************************************************************************************
skipping: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru -> db01.lodyanyy.ru]

TASK [mysql : Configure replication on the slave.] ********************************************************************************************************************
skipping: [db01.lodyanyy.ru]
changed: [db02.lodyanyy.ru]

TASK [mysql : Start replication.] *************************************************************************************************************************************
skipping: [db01.lodyanyy.ru]
changed: [db02.lodyanyy.ru]

PLAY RECAP ************************************************************************************************************************************************************
db01.lodyanyy.ru           : ok=39   changed=3    unreachable=0    failed=0    skipped=17   rescued=0    ignored=0   
db02.lodyanyy.ru           : ok=42   changed=3    unreachable=0    failed=0    skipped=14   rescued=0    ignored=0
```
</details>


Проверка репликации на мастере:  
  
```bash
ubuntu@db01:~$ mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 30
Server version: 8.0.30-0ubuntu0.20.04.2 (Ubuntu)

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show master status\G
*************************** 1. row ***************************
             File: mysql-bin.000002
         Position: 5095
     Binlog_Do_DB: wordpress
 Binlog_Ignore_DB: 
Executed_Gtid_Set: 
1 row in set (0.00 sec)

mysql> show slave hosts;
+-----------+------+------+-----------+--------------------------------------+
| Server_id | Host | Port | Master_id | Slave_UUID                           |
+-----------+------+------+-----------+--------------------------------------+
|         2 |      | 3306 |         1 | 242293b4-4985-11ed-8c0a-d00de64110b4 |
+-----------+------+------+-----------+--------------------------------------+
1 row in set, 1 warning (0.00 sec)

```  
Проверка репликации на реплике:

```bash
ubuntu@db02:~$ mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 23
Server version: 8.0.30-0ubuntu0.20.04.2 (Ubuntu)

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show slave status\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for source to send event
                  Master_Host: db01.lodyanyy.ru
                  Master_User: repuser
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 5095
               Relay_Log_File: relay-bin.000004
                Relay_Log_Pos: 2795
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: 
          Replicate_Ignore_DB: 
           Replicate_Do_Table: 
       Replicate_Ignore_Table: 
      Replicate_Wild_Do_Table: 
  Replicate_Wild_Ignore_Table: 
                   Last_Errno: 0
                   Last_Error: 
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 5095
              Relay_Log_Space: 3348
              Until_Condition: None
               Until_Log_File: 
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File: 
           Master_SSL_CA_Path: 
              Master_SSL_Cert: 
            Master_SSL_Cipher: 
               Master_SSL_Key: 
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error: 
               Last_SQL_Errno: 0
               Last_SQL_Error: 
  Replicate_Ignore_Server_Ids: 
             Master_Server_Id: 1
                  Master_UUID: b15278fe-4984-11ed-a711-d00d18e21246
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Replica has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind: 
      Last_IO_Error_Timestamp: 
     Last_SQL_Error_Timestamp: 
               Master_SSL_Crl: 
           Master_SSL_Crlpath: 
           Retrieved_Gtid_Set: 
            Executed_Gtid_Set: 
                Auto_Position: 0
         Replicate_Rewrite_DB: 
                 Channel_Name: 
           Master_TLS_Version: 
       Master_public_key_path: 
        Get_master_public_key: 0
            Network_Namespace: 
1 row in set, 1 warning (0.00 sec)
```
В кластере создается база данных wordpress и пользователь wordpress с полными правами на базу и паролем wordpress:
```bash
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| wordpress          |
+--------------------+
5 rows in set (0.00 sec)

mysql> SELECT User, Host FROM mysql.user;
+------------------+-----------+
| User             | Host      |
+------------------+-----------+
| repuser          | %         |
| wordpress        | %         |
| debian-sys-maint | localhost |
| mysql.infoschema | localhost |
| mysql.session    | localhost |
| mysql.sys        | localhost |
| root             | localhost |
| ubuntu           | localhost |
+------------------+-----------+
```  
  
## 5. Установка WordPress  

<details>
<summary> ansible-playbook wordpress.yml -i hosts </summary> 

```bash
ubuntu@lodyanyynote:~/netology/diplom/ansible$ ansible-playbook wordpress.yml -i hosts

PLAY [app] ************************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************
ok: [app.lodyanyy.ru]

TASK [update : Update apt repo and cache on all Debian/Ubuntu boxes] **************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [nginx : Install nginx] ******************************************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [nginx : Disable default site] ***********************************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [memcached : install memcached server] ***************************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [php5 : Upgrade system] ******************************************************************************************************************************************
ok: [app.lodyanyy.ru]

TASK [php5 : install php7.4] ******************************************************************************************************************************************
changed: [app.lodyanyy.ru] => (item=php7.4)
changed: [app.lodyanyy.ru] => (item=php7.4-cgi)
changed: [app.lodyanyy.ru] => (item=php-fpm)
changed: [app.lodyanyy.ru] => (item=php7.4-memcache)
changed: [app.lodyanyy.ru] => (item=php7.4-memcached)
changed: [app.lodyanyy.ru] => (item=php7.4-mysql)
changed: [app.lodyanyy.ru] => (item=php7.4-gd)
changed: [app.lodyanyy.ru] => (item=php7.4-curl)
changed: [app.lodyanyy.ru] => (item=php7.4-xmlrpc)

TASK [php5 : change listen socket] ************************************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [wordpress : Install git] ****************************************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [wordpress : install nginx configuration] ************************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [wordpress : activate site configuration] ************************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [wordpress : download WordPress] *********************************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [wordpress : creating directory for WordPress] *******************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [wordpress : unpack WordPress installation] **********************************************************************************************************************
changed: [app.lodyanyy.ru]

TASK [wordpress : wordpress php] **************************************************************************************************************************************
changed: [app.lodyanyy.ru]

RUNNING HANDLER [nginx : restart nginx] *******************************************************************************************************************************
changed: [app.lodyanyy.ru]

RUNNING HANDLER [php5 : restart php-fpm] ******************************************************************************************************************************
changed: [app.lodyanyy.ru]

PLAY RECAP ************************************************************************************************************************************************************
app.lodyanyy.ru            : ok=17   changed=15   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```
</details>  
  
Первоначальная настройка wordpress:
  
![](https://user-images.githubusercontent.com/87534423/195161873-c7f710cd-0fc2-4719-86b2-caf6fc40fe9c.jpg)  
  
Страничка сайта:
  
![wp3](https://user-images.githubusercontent.com/87534423/195162013-4e46d790-0b3d-4f28-9bd0-c345222b4398.jpg)

## 6. Установка Gitlab CE и Gitlab Runner  
  
<details>
<summary> ansible-playbook gitlab.yml -i hosts </summary> 

```bash
ubuntu@lodyanyynote:~/netology/diplom/ansible$ ansible-playbook gitlab.yml -i hosts

PLAY [gitlab] *********************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************
ok: [gitlab.lodyanyy.ru]

TASK [update : Update apt repo and cache on all Debian/Ubuntu boxes] **************************************************************************************************
changed: [gitlab.lodyanyy.ru]

TASK [gitlab : Include OS-specific variables.] ************************************************************************************************************************
ok: [gitlab.lodyanyy.ru]

TASK [gitlab : Check if GitLab configuration file already exists.] ****************************************************************************************************
ok: [gitlab.lodyanyy.ru]

TASK [gitlab : Check if GitLab is already installed.] *****************************************************************************************************************
ok: [gitlab.lodyanyy.ru]

TASK [gitlab : Install GitLab dependencies.] **************************************************************************************************************************
changed: [gitlab.lodyanyy.ru]

TASK [gitlab : Install GitLab dependencies (Debian).] *****************************************************************************************************************
changed: [gitlab.lodyanyy.ru]

TASK [gitlab : Download GitLab repository installation script.] *******************************************************************************************************
changed: [gitlab.lodyanyy.ru]

TASK [gitlab : Install GitLab repository.] ****************************************************************************************************************************
changed: [gitlab.lodyanyy.ru]

TASK [gitlab : Define the Gitlab package name.] ***********************************************************************************************************************
skipping: [gitlab.lodyanyy.ru]

TASK [gitlab : Install GitLab] ****************************************************************************************************************************************
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC POLL on gitlab.lodyanyy.ru: jid=771836116235.3652 started=1 finished=0
ASYNC OK on gitlab.lodyanyy.ru: jid=771836116235.3652
changed: [gitlab.lodyanyy.ru]

TASK [gitlab : Reconfigure GitLab (first run).] ***********************************************************************************************************************
changed: [gitlab.lodyanyy.ru]

TASK [gitlab : Create GitLab SSL configuration folder.] ***************************************************************************************************************
skipping: [gitlab.lodyanyy.ru]

TASK [gitlab : Create self-signed certificate.] ***********************************************************************************************************************
skipping: [gitlab.lodyanyy.ru]

TASK [gitlab : Copy GitLab configuration file.] ***********************************************************************************************************************
changed: [gitlab.lodyanyy.ru]

RUNNING HANDLER [gitlab : restart gitlab] *****************************************************************************************************************************
changed: [gitlab.lodyanyy.ru]

PLAY RECAP ************************************************************************************************************************************************************
gitlab.lodyanyy.ru         : ok=13   changed=9    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0
```
</details>
  
Меняем пароль на gitlab.lodyanyy.ru для root пользователя:
```bash
ubuntu@gitlab:~$ sudo gitlab-rake "gitlab:password:reset[root]"
Enter password: 
Confirm password: 
Password successfully updated for user with username root.
```
Указываем токен гитлаба в роли gitlab_runner в файле /defaults/main.yml

![](https://user-images.githubusercontent.com/87534423/195166609-b66e2809-8404-419b-9176-9cf259b47ad1.jpg)
  
Запускаем плейбук гитлаб раннер:  
  
<details>
<summary> ansible-playbook runner.yml -i hosts </summary> 

```bash
ubuntu@lodyanyynote:~/netology/diplom/ansible$ ansible-playbook runner.yml -i hosts

PLAY [runner] *********************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [update : Update apt repo and cache on all Debian/Ubuntu boxes] **************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : Load platform-specific variables] ***************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Container) Pull Image from Registry] ***********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Container) Define Container volume Path] *******************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Container) List configured runners] ************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Container) Check runner is registered] *********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : configured_runners?] ****************************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : verified_runners?] ******************************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Container) Register GitLab Runner] *************************************************************************************************************
skipping: [runner.lodyanyy.ru] => (item={'name': 'runner', 'state': 'present', 'executor': 'shell', 'output_limit': 4096, 'concurrent_specific': '0', 'docker_image': '', 'tags': [], 'run_untagged': True, 'protected': False, 'docker_privileged': False, 'locked': 'false', 'docker_network_mode': 'bridge', 'env_vars': []})              

TASK [gitlab_runner : Create .gitlab-runner dir] **********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Ensure config.toml exists] **********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Set concurrent option] **************************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add listen_address to config] *******************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add log_format to config] ***********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add sentry dsn to config] ***********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add session server listen_address to config] ****************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add session server advertise_address to config] *************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add session server session_timeout to config] ***************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Get existing config.toml] ***********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Get pre-existing runner configs] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Create temporary directory] *********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Write config section for each runner] ***********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Assemble new config.toml] ***********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Container) Start the container] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Debian) Get Gitlab repository installation script] *********************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Debian) Install Gitlab repository] *************************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Debian) Update gitlab_runner_package_name] *****************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Debian) Set gitlab_runner_package_name] ********************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Debian) Install GitLab Runner] *****************************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Debian) Install GitLab Runner] *****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Debian) Remove ~/gitlab-runner/.bash_logout on debian buster and ubuntu focal] *****************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Ensure /etc/systemd/system/gitlab-runner.service.d/ exists] *************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add reload command to GitLab Runner system service] *********************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : Configure graceful stop for GitLab Runner system service] ***************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : Force systemd to reread configs] ****************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : (RedHat) Get Gitlab repository installation script] *********************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (RedHat) Install Gitlab repository] *************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (RedHat) Update gitlab_runner_package_name] *****************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (RedHat) Set gitlab_runner_package_name] ********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (RedHat) Install GitLab Runner] *****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Ensure /etc/systemd/system/gitlab-runner.service.d/ exists] *************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add reload command to GitLab Runner system service] *********************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Configure graceful stop for GitLab Runner system service] ***************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Force systemd to reread configs] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Check gitlab-runner executable exists] **************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Set fact -> gitlab_runner_exists] *******************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Get existing version] *******************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Set fact -> gitlab_runner_existing_version] *********************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Precreate gitlab-runner log directory] **************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Download GitLab Runner] *****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Setting Permissions for gitlab-runner executable] ***************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Install GitLab Runner] ******************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Start GitLab Runner] ********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Stop GitLab Runner] *********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Download GitLab Runner] *****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Setting Permissions for gitlab-runner executable] ***************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (MacOS) Start GitLab Runner] ********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Arch) Set gitlab_runner_package_name] **********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Arch) Install GitLab Runner] *******************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Ensure /etc/systemd/system/gitlab-runner.service.d/ exists] *************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add reload command to GitLab Runner system service] *********************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Configure graceful stop for GitLab Runner system service] ***************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Force systemd to reread configs] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Unix) List configured runners] *****************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Unix) Check runner is registered] **************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Unix) Register GitLab Runner] ******************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/gitlab_runner/tasks/register-runner.yml for runner.lodyanyy.ru => (item={'name': 'runner', 'state': 'present', 'executor': 'shell', 'output_limit': 4096, 'concurrent_specific': '0', 'docker_image': '', 'tags': [], 'run_untagged': True, 'protected': False, 'docker_privileged': False, 'locked': 'false', 'docker_network_mode': 'bridge', 'env_vars': []})                                                                                                

TASK [gitlab_runner : remove config.toml file] ************************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Create .gitlab-runner dir] **********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Ensure config.toml exists] **********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Construct the runner command without secrets] ***************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Register runner to GitLab] **********************************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : Create .gitlab-runner dir] **********************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Ensure config.toml exists] **********************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Set concurrent option] **************************************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add listen_address to config] *******************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add log_format to config] ***********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add sentry dsn to config] ***********************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add session server listen_address to config] ****************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add session server advertise_address to config] *************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Add session server session_timeout to config] ***************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Get existing config.toml] ***********************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Get pre-existing runner configs] ****************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Create temporary directory] *********************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : Write config section for each runner] ***********************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/gitlab_runner/tasks/config-runner.yml for runner.lodyanyy.ru => (item=concurrent = 4
check_interval = 0

[session_server]
  session_timeout = 1800

)
included: /home/ubuntu/netology/diplom/ansible/roles/gitlab_runner/tasks/config-runner.yml for runner.lodyanyy.ru => (item=  name = "runner"
  output_limit = 4096
  url = "http://gitlab.lodyanyy.ru/"
  id = 1
  token = "oX-FyVybgrXnYXssgvY2"
  token_obtained_at = 2022-10-11T18:13:02Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "shell"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
)

TASK [gitlab_runner : conf[1/2]: Create temporary file] ***************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[1/2]: Isolate runner configuration] ********************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : include_tasks] **********************************************************************************************************************************
skipping: [runner.lodyanyy.ru] => (item={'name': 'runner', 'state': 'present', 'executor': 'shell', 'output_limit': 4096, 'concurrent_specific': '0', 'docker_image': '', 'tags': [], 'run_untagged': True, 'protected': False, 'docker_privileged': False, 'locked': 'false', 'docker_network_mode': 'bridge', 'env_vars': []})              

TASK [gitlab_runner : conf[1/2]: Remove runner config] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru] => (item={'name': 'runner', 'state': 'present', 'executor': 'shell', 'output_limit': 4096, 'concurrent_specific': '0', 'docker_image': '', 'tags': [], 'run_untagged': True, 'protected': False, 'docker_privileged': False, 'locked': 'false', 'docker_network_mode': 'bridge', 'env_vars': []})              

TASK [gitlab_runner : conf[2/2]: Create temporary file] ***************************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: Isolate runner configuration] ********************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : include_tasks] **********************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/gitlab_runner/tasks/update-config-runner.yml for runner.lodyanyy.ru => (item={'name': 'runner', 'state': 'present', 'executor': 'shell', 'output_limit': 4096, 'concurrent_specific': '0', 'docker_image': '', 'tags': [], 'run_untagged': True, 'protected': False, 'docker_privileged': False, 'locked': 'false', 'docker_network_mode': 'bridge', 'env_vars': []})                                                                                           

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set concurrent limit option] ********************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set coordinator URL] ****************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set clone URL] **********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set environment option] *************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set pre_clone_script] ***************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set pre_build_script] ***************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set tls_ca_file] ********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set post_build_script] **************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set runner executor option] *********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set runner shell option] ************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set runner executor section] ********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set output_limit option] ************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set runner docker image option] *****************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker helper image option] *****************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker privileged option] *******************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker wait_for_services_timeout option] ****************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker tlsverify option] ********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker shm_size option] *********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker disable_cache option] ****************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker DNS option] **************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker DNS search option] *******************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker pull_policy option] ******************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker volumes option] **********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker devices option] **********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set runner docker network option] ***************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set custom_build_dir section] *******************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set docker custom_build_dir-enabled option] *****************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache section] ******************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache s3 section] ***************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache gcs section] **************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache azure section] ************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache type option] **************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache path option] **************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache shared option] ************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache s3 server addresss] *******************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache s3 access key] ************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache s3 secret key] ************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache s3 bucket name option] ****************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache s3 bucket location option] ************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache s3 insecure option] *******************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache gcs bucket name] **********************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache gcs credentials file] *****************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache gcs access id] ************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache gcs private key] **********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache azure account name] *******************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache azure account key] ********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache azure container name] *****************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache azure storage domain] *****************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set ssh user option] ****************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set ssh host option] ****************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set ssh port option] ****************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set ssh password option] ************************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set ssh identity file option] *******************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set virtualbox base name option] ****************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set virtualbox base snapshot option] ************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set virtualbox base folder option] **************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set virtualbox disable snapshots option] ********************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set builds dir file option] *********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Set cache dir file option] **********************************************************************************************
ok: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Ensure directory permissions] *******************************************************************************************
skipping: [runner.lodyanyy.ru] => (item=) 
skipping: [runner.lodyanyy.ru] => (item=) 

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Ensure directory access test] *******************************************************************************************
skipping: [runner.lodyanyy.ru] => (item=) 
skipping: [runner.lodyanyy.ru] => (item=) 

TASK [gitlab_runner : conf[2/2]: runner[1/1]: Ensure directory access fail on error] **********************************************************************************
skipping: [runner.lodyanyy.ru] => (item={'changed': False, 'skipped': True, 'skip_reason': 'Conditional result was False', 'item': '', 'ansible_loop_var': 'item'}) 
skipping: [runner.lodyanyy.ru] => (item={'changed': False, 'skipped': True, 'skip_reason': 'Conditional result was False', 'item': '', 'ansible_loop_var': 'item'}) 

TASK [gitlab_runner : include_tasks] **********************************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : conf[2/2]: Remove runner config] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru] => (item={'name': 'runner', 'state': 'present', 'executor': 'shell', 'output_limit': 4096, 'concurrent_specific': '0', 'docker_image': '', 'tags': [], 'run_untagged': True, 'protected': False, 'docker_privileged': False, 'locked': 'false', 'docker_network_mode': 'bridge', 'env_vars': []})              

TASK [gitlab_runner : Assemble new config.toml] ***********************************************************************************************************************
changed: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Check gitlab-runner executable exists] ************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Set fact -> gitlab_runner_exists] *****************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Get existing version] *****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Set fact -> gitlab_runner_existing_version] *******************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Ensure install directory exists] ******************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Download GitLab Runner] ***************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Install GitLab Runner] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Install GitLab Runner] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Make sure runner is stopped] **********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Download GitLab Runner] ***************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) List configured runners] **************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Check runner is registered] ***********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Register GitLab Runner] ***************************************************************************************************************
skipping: [runner.lodyanyy.ru] => (item={'name': 'runner', 'state': 'present', 'executor': 'shell', 'output_limit': 4096, 'concurrent_specific': '0', 'docker_image': '', 'tags': [], 'run_untagged': True, 'protected': False, 'docker_privileged': False, 'locked': 'false', 'docker_network_mode': 'bridge', 'env_vars': []})              

TASK [gitlab_runner : (Windows) Create .gitlab-runner dir] ************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Ensure config.toml exists] ************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Set concurrent option] ****************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Add listen_address to config] *********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Add sentry dsn to config] *************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Add session server listen_address to config] ******************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Add session server advertise_address to config] ***************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Add session server session_timeout to config] *****************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Get existing config.toml] *************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Get pre-existing global config] *******************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Get pre-existing runner configs] ******************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Create temporary directory] ***********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Write config section for each runner] *************************************************************************************************
skipping: [runner.lodyanyy.ru] => (item=concurrent = 4
check_interval = 0

[session_server]
  session_timeout = 1800

) 
skipping: [runner.lodyanyy.ru] => (item=  name = "runner"
  output_limit = 4096
  url = "http://gitlab.lodyanyy.ru/"
  id = 1
  token = "oX-FyVybgrXnYXssgvY2"
  token_obtained_at = 2022-10-11T18:13:02Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "shell"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
) 

TASK [gitlab_runner : (Windows) Create temporary file config.toml] ****************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Write global config to file] **********************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Create temporary file runners-config.toml] ********************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Assemble runners files in config dir] *************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Assemble new config.toml] *************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Verify config] ************************************************************************************************************************
skipping: [runner.lodyanyy.ru]

TASK [gitlab_runner : (Windows) Start GitLab Runner] ******************************************************************************************************************
skipping: [runner.lodyanyy.ru]

RUNNING HANDLER [gitlab_runner : restart_gitlab_runner] ***************************************************************************************************************
changed: [runner.lodyanyy.ru]

RUNNING HANDLER [gitlab_runner : restart_gitlab_runner_macos] *********************************************************************************************************
skipping: [runner.lodyanyy.ru]

PLAY RECAP ************************************************************************************************************************************************************
runner.lodyanyy.ru         : ok=83   changed=20   unreachable=0    failed=0    skipped=110  rescued=0    ignored=0 
```
</details>

Добавляем переменную ssh_key:
  
![](https://user-images.githubusercontent.com/87534423/195170419-3bec94fe-7ceb-4501-8408-af1b959d1fb5.jpg)

Для автоматического деплоя на виртуальную машину app.lodyanyy.ru при любом коммите в репозитарий создан следующий пайплайн:
```yml
before_script:
  - eval $(ssh-agent -s)
  - echo "$ssh_key" | tr -d '\r' | ssh-add -
  - mkdir -p ~/.ssh
  - chmod 700 ~/.ssh

stages:         
  - deploy

deploy-job:      
  stage: deploy
  script: 
    - echo "Deploying application..." 
    - ssh -o StrictHostKeyChecking=no ubuntu@app.lodyanyy.ru sudo chown ubuntu /var/www/wordpress/ -R
    - scp -o StrictHostKeyChecking=no -r ./* ubuntu@app.lodyanyy.ru:/var/www/wordpress/
    - ssh -o StrictHostKeyChecking=no ubuntu@app.lodyanyy.ru rm -rf /var/www/wordpress/.git
    - ssh -o StrictHostKeyChecking=no ubuntu@app.lodyanyy.ru sudo chown www-data /var/www/wordpress/ -R
```
![](https://user-images.githubusercontent.com/87534423/195174199-26b59b17-d588-43a3-807b-4e73120d5393.jpg)
![](https://user-images.githubusercontent.com/87534423/195174382-e8077510-2c76-46d6-a2de-d1ca9f890ac1.jpg)
  
## 7. Установка Prometheus, Alert Manager, Node Exporter и Grafana
  
<details>
<summary> ansible-playbook node_exporter.yml -i hosts </summary> 

```bash
ubuntu@lodyanyynote:~/netology/diplom/ansible$ ansible-playbook node_exporter.yml -i hosts

PLAY [mysql app gitlab runner monitoring] *****************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [app.lodyanyy.ru]
ok: [runner.lodyanyy.ru]
ok: [db02.lodyanyy.ru]
ok: [gitlab.lodyanyy.ru]
ok: [monitoring.lodyanyy.ru]

TASK [update : Update apt repo and cache on all Debian/Ubuntu boxes] **************************************************************************************************
changed: [db01.lodyanyy.ru]
changed: [app.lodyanyy.ru]
changed: [db02.lodyanyy.ru]
changed: [runner.lodyanyy.ru]
changed: [gitlab.lodyanyy.ru]
changed: [monitoring.lodyanyy.ru]

TASK [node_exporter : Assert usage of systemd as an init system] ******************************************************************************************************
ok: [db01.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [db02.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [app.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [gitlab.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [runner.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [monitoring.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [node_exporter : Get systemd version] ****************************************************************************************************************************
ok: [runner.lodyanyy.ru]
ok: [db02.lodyanyy.ru]
ok: [app.lodyanyy.ru]
ok: [db01.lodyanyy.ru]
ok: [gitlab.lodyanyy.ru]
ok: [monitoring.lodyanyy.ru]

TASK [node_exporter : Set systemd version fact] ***********************************************************************************************************************
ok: [db01.lodyanyy.ru]
ok: [db02.lodyanyy.ru]
ok: [app.lodyanyy.ru]
ok: [gitlab.lodyanyy.ru]
ok: [runner.lodyanyy.ru]
ok: [monitoring.lodyanyy.ru]

TASK [node_exporter : Naive assertion of proper listen address] *******************************************************************************************************
ok: [db01.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [db02.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [app.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [gitlab.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [runner.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}
ok: [monitoring.lodyanyy.ru] => {
    "changed": false,
    "msg": "All assertions passed"
}

TASK [node_exporter : Assert collectors are not both disabled and enabled at the same time] ***************************************************************************

TASK [node_exporter : Assert that TLS key and cert path are set] ******************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Check existence of TLS cert file] ***************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Check existence of TLS key file] ****************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Assert that TLS key and cert are present] *******************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Check if node_exporter is installed] ************************************************************************************************************
ok: [runner.lodyanyy.ru]
ok: [db01.lodyanyy.ru]
ok: [app.lodyanyy.ru]
ok: [gitlab.lodyanyy.ru]
ok: [db02.lodyanyy.ru]
ok: [monitoring.lodyanyy.ru]

TASK [node_exporter : Gather currently installed node_exporter version (if any)] **************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Get latest release] *****************************************************************************************************************************
skipping: [db01.lodyanyy.ru]

TASK [node_exporter : Set node_exporter version to {{ _latest_release.json.tag_name[1:] }}] ***************************************************************************
skipping: [db01.lodyanyy.ru]

TASK [node_exporter : Get checksum list from github] ******************************************************************************************************************
ok: [db01.lodyanyy.ru -> localhost]

TASK [node_exporter : Get checksum for amd64 architecture] ************************************************************************************************************
skipping: [db01.lodyanyy.ru] => (item=3919266f1dbad5f7e5ce7b4207057fc253a8322f570607cc0f3e73f4a53338e3  node_exporter-1.1.2.darwin-amd64.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=5b0195e203dedd3a8973cd1894a55097554a4af6d8f4f0614c2c67d6670ea8ae  node_exporter-1.1.2.linux-386.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=3919266f1dbad5f7e5ce7b4207057fc253a8322f570607cc0f3e73f4a53338e3  node_exporter-1.1.2.darwin-amd64.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=5b0195e203dedd3a8973cd1894a55097554a4af6d8f4f0614c2c67d6670ea8ae  node_exporter-1.1.2.linux-386.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=3919266f1dbad5f7e5ce7b4207057fc253a8322f570607cc0f3e73f4a53338e3  node_exporter-1.1.2.darwin-amd64.tar.gz) 
ok: [db01.lodyanyy.ru -> localhost] => (item=8c1f6a317457a658e0ae68ad710f6b4098db2cad10204649b51e3c043aa3e70d  node_exporter-1.1.2.linux-amd64.tar.gz)
skipping: [app.lodyanyy.ru] => (item=5b0195e203dedd3a8973cd1894a55097554a4af6d8f4f0614c2c67d6670ea8ae  node_exporter-1.1.2.linux-386.tar.gz) 
ok: [db02.lodyanyy.ru -> localhost] => (item=8c1f6a317457a658e0ae68ad710f6b4098db2cad10204649b51e3c043aa3e70d  node_exporter-1.1.2.linux-amd64.tar.gz)
skipping: [db01.lodyanyy.ru] => (item=eb5e7d16f18bb3272d0d832986fc8ac6cb0b6c42d487c94e15dabb10feae8e04  node_exporter-1.1.2.linux-arm64.tar.gz) 
ok: [app.lodyanyy.ru -> localhost] => (item=8c1f6a317457a658e0ae68ad710f6b4098db2cad10204649b51e3c043aa3e70d  node_exporter-1.1.2.linux-amd64.tar.gz)
skipping: [app.lodyanyy.ru] => (item=eb5e7d16f18bb3272d0d832986fc8ac6cb0b6c42d487c94e15dabb10feae8e04  node_exporter-1.1.2.linux-arm64.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=41892e451e80160491a1cc7bbe6bccd6cb842ae8340e1bc6e32f72cefb1aee80  node_exporter-1.1.2.linux-armv5.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=eb5e7d16f18bb3272d0d832986fc8ac6cb0b6c42d487c94e15dabb10feae8e04  node_exporter-1.1.2.linux-arm64.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=41892e451e80160491a1cc7bbe6bccd6cb842ae8340e1bc6e32f72cefb1aee80  node_exporter-1.1.2.linux-armv5.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=3919266f1dbad5f7e5ce7b4207057fc253a8322f570607cc0f3e73f4a53338e3  node_exporter-1.1.2.darwin-amd64.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=3919266f1dbad5f7e5ce7b4207057fc253a8322f570607cc0f3e73f4a53338e3  node_exporter-1.1.2.darwin-amd64.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=5b0195e203dedd3a8973cd1894a55097554a4af6d8f4f0614c2c67d6670ea8ae  node_exporter-1.1.2.linux-386.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=41892e451e80160491a1cc7bbe6bccd6cb842ae8340e1bc6e32f72cefb1aee80  node_exporter-1.1.2.linux-armv5.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=1cc1bf4cacb84d6c228d9ce8045b5b00b73afd954046f7b2add428a04d14daee  node_exporter-1.1.2.linux-armv6.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=1cc1bf4cacb84d6c228d9ce8045b5b00b73afd954046f7b2add428a04d14daee  node_exporter-1.1.2.linux-armv6.tar.gz) 
ok: [runner.lodyanyy.ru -> localhost] => (item=8c1f6a317457a658e0ae68ad710f6b4098db2cad10204649b51e3c043aa3e70d  node_exporter-1.1.2.linux-amd64.tar.gz)
skipping: [runner.lodyanyy.ru] => (item=eb5e7d16f18bb3272d0d832986fc8ac6cb0b6c42d487c94e15dabb10feae8e04  node_exporter-1.1.2.linux-arm64.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=5b0195e203dedd3a8973cd1894a55097554a4af6d8f4f0614c2c67d6670ea8ae  node_exporter-1.1.2.linux-386.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=a9fe816eb7b976b1587d6d654c437f7d78349f70686fa22ae33e94fe84281af2  node_exporter-1.1.2.linux-armv7.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=a9fe816eb7b976b1587d6d654c437f7d78349f70686fa22ae33e94fe84281af2  node_exporter-1.1.2.linux-armv7.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=41892e451e80160491a1cc7bbe6bccd6cb842ae8340e1bc6e32f72cefb1aee80  node_exporter-1.1.2.linux-armv5.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=1cc1bf4cacb84d6c228d9ce8045b5b00b73afd954046f7b2add428a04d14daee  node_exporter-1.1.2.linux-armv6.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=1cc1bf4cacb84d6c228d9ce8045b5b00b73afd954046f7b2add428a04d14daee  node_exporter-1.1.2.linux-armv6.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=a9fe816eb7b976b1587d6d654c437f7d78349f70686fa22ae33e94fe84281af2  node_exporter-1.1.2.linux-armv7.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=a99ab2cdc62db25ff01d184e21ad433e3949cd791fc2c80b6bacc6b90d5a62c2  node_exporter-1.1.2.linux-mips.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=a99ab2cdc62db25ff01d184e21ad433e3949cd791fc2c80b6bacc6b90d5a62c2  node_exporter-1.1.2.linux-mips.tar.gz) 
ok: [gitlab.lodyanyy.ru -> localhost] => (item=8c1f6a317457a658e0ae68ad710f6b4098db2cad10204649b51e3c043aa3e70d  node_exporter-1.1.2.linux-amd64.tar.gz)
skipping: [runner.lodyanyy.ru] => (item=a99ab2cdc62db25ff01d184e21ad433e3949cd791fc2c80b6bacc6b90d5a62c2  node_exporter-1.1.2.linux-mips.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=a9fe816eb7b976b1587d6d654c437f7d78349f70686fa22ae33e94fe84281af2  node_exporter-1.1.2.linux-armv7.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=a99ab2cdc62db25ff01d184e21ad433e3949cd791fc2c80b6bacc6b90d5a62c2  node_exporter-1.1.2.linux-mips.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=eb5e7d16f18bb3272d0d832986fc8ac6cb0b6c42d487c94e15dabb10feae8e04  node_exporter-1.1.2.linux-arm64.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=22d9c2a5363502c79e0645ba02eafd9561b33d1e0e819ce4df3fcf7dc96e3792  node_exporter-1.1.2.linux-mips64.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=22d9c2a5363502c79e0645ba02eafd9561b33d1e0e819ce4df3fcf7dc96e3792  node_exporter-1.1.2.linux-mips64.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=22d9c2a5363502c79e0645ba02eafd9561b33d1e0e819ce4df3fcf7dc96e3792  node_exporter-1.1.2.linux-mips64.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=22d9c2a5363502c79e0645ba02eafd9561b33d1e0e819ce4df3fcf7dc96e3792  node_exporter-1.1.2.linux-mips64.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=a66b70690c3c4fff953905a041c74834f96be85a806e74a1cc925e607ef50a26  node_exporter-1.1.2.linux-mips64le.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=f7fba791cbc758b021d0e9a2400c82d1f29337e568ab00edc84b053ca467ea3c  node_exporter-1.1.2.linux-mipsle.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=a66b70690c3c4fff953905a041c74834f96be85a806e74a1cc925e607ef50a26  node_exporter-1.1.2.linux-mips64le.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=41892e451e80160491a1cc7bbe6bccd6cb842ae8340e1bc6e32f72cefb1aee80  node_exporter-1.1.2.linux-armv5.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=a66b70690c3c4fff953905a041c74834f96be85a806e74a1cc925e607ef50a26  node_exporter-1.1.2.linux-mips64le.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=294c0b05dff4f368512449de7268e3f06de679a9343e9885044adc702865080b  node_exporter-1.1.2.linux-ppc64.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=a66b70690c3c4fff953905a041c74834f96be85a806e74a1cc925e607ef50a26  node_exporter-1.1.2.linux-mips64le.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=d1d201b16d757980db654bb9e448ab0c81ca4c2715243c3fa4305bef5967bd41  node_exporter-1.1.2.linux-ppc64le.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=f7fba791cbc758b021d0e9a2400c82d1f29337e568ab00edc84b053ca467ea3c  node_exporter-1.1.2.linux-mipsle.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=f7fba791cbc758b021d0e9a2400c82d1f29337e568ab00edc84b053ca467ea3c  node_exporter-1.1.2.linux-mipsle.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=6007420f425d08626c05de2dbe0e8bb785a16bba1b02c01cb06d37d7fab3bc97  node_exporter-1.1.2.linux-s390x.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=f7fba791cbc758b021d0e9a2400c82d1f29337e568ab00edc84b053ca467ea3c  node_exporter-1.1.2.linux-mipsle.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=294c0b05dff4f368512449de7268e3f06de679a9343e9885044adc702865080b  node_exporter-1.1.2.linux-ppc64.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=1cc1bf4cacb84d6c228d9ce8045b5b00b73afd954046f7b2add428a04d14daee  node_exporter-1.1.2.linux-armv6.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=294c0b05dff4f368512449de7268e3f06de679a9343e9885044adc702865080b  node_exporter-1.1.2.linux-ppc64.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=d1d201b16d757980db654bb9e448ab0c81ca4c2715243c3fa4305bef5967bd41  node_exporter-1.1.2.linux-ppc64le.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=0596e9c1cc358e6fcc60cb83f0d1ba9a37ccee11eca035429c9791c0beb04389  node_exporter-1.1.2.netbsd-386.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=294c0b05dff4f368512449de7268e3f06de679a9343e9885044adc702865080b  node_exporter-1.1.2.linux-ppc64.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=a9fe816eb7b976b1587d6d654c437f7d78349f70686fa22ae33e94fe84281af2  node_exporter-1.1.2.linux-armv7.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=6007420f425d08626c05de2dbe0e8bb785a16bba1b02c01cb06d37d7fab3bc97  node_exporter-1.1.2.linux-s390x.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=d1d201b16d757980db654bb9e448ab0c81ca4c2715243c3fa4305bef5967bd41  node_exporter-1.1.2.linux-ppc64le.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=d1d201b16d757980db654bb9e448ab0c81ca4c2715243c3fa4305bef5967bd41  node_exporter-1.1.2.linux-ppc64le.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=0596e9c1cc358e6fcc60cb83f0d1ba9a37ccee11eca035429c9791c0beb04389  node_exporter-1.1.2.netbsd-386.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=46c964efd336f0e35f62c739ce9edf5409911e7652604e411c9b684eb9c48386  node_exporter-1.1.2.netbsd-amd64.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=a99ab2cdc62db25ff01d184e21ad433e3949cd791fc2c80b6bacc6b90d5a62c2  node_exporter-1.1.2.linux-mips.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=46c964efd336f0e35f62c739ce9edf5409911e7652604e411c9b684eb9c48386  node_exporter-1.1.2.netbsd-amd64.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=6007420f425d08626c05de2dbe0e8bb785a16bba1b02c01cb06d37d7fab3bc97  node_exporter-1.1.2.linux-s390x.tar.gz) 
skipping: [db02.lodyanyy.ru] => (item=d81f86f57a4ed167a4062aa47f8a70b35c146c86bc8e40924c9d1fc3644ec8e6  node_exporter-1.1.2.openbsd-amd64.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=6007420f425d08626c05de2dbe0e8bb785a16bba1b02c01cb06d37d7fab3bc97  node_exporter-1.1.2.linux-s390x.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=22d9c2a5363502c79e0645ba02eafd9561b33d1e0e819ce4df3fcf7dc96e3792  node_exporter-1.1.2.linux-mips64.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=0596e9c1cc358e6fcc60cb83f0d1ba9a37ccee11eca035429c9791c0beb04389  node_exporter-1.1.2.netbsd-386.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=a66b70690c3c4fff953905a041c74834f96be85a806e74a1cc925e607ef50a26  node_exporter-1.1.2.linux-mips64le.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=0596e9c1cc358e6fcc60cb83f0d1ba9a37ccee11eca035429c9791c0beb04389  node_exporter-1.1.2.netbsd-386.tar.gz) 
skipping: [runner.lodyanyy.ru] => (item=d81f86f57a4ed167a4062aa47f8a70b35c146c86bc8e40924c9d1fc3644ec8e6  node_exporter-1.1.2.openbsd-amd64.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=46c964efd336f0e35f62c739ce9edf5409911e7652604e411c9b684eb9c48386  node_exporter-1.1.2.netbsd-amd64.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=46c964efd336f0e35f62c739ce9edf5409911e7652604e411c9b684eb9c48386  node_exporter-1.1.2.netbsd-amd64.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=f7fba791cbc758b021d0e9a2400c82d1f29337e568ab00edc84b053ca467ea3c  node_exporter-1.1.2.linux-mipsle.tar.gz) 
skipping: [db01.lodyanyy.ru] => (item=d81f86f57a4ed167a4062aa47f8a70b35c146c86bc8e40924c9d1fc3644ec8e6  node_exporter-1.1.2.openbsd-amd64.tar.gz) 
skipping: [app.lodyanyy.ru] => (item=d81f86f57a4ed167a4062aa47f8a70b35c146c86bc8e40924c9d1fc3644ec8e6  node_exporter-1.1.2.openbsd-amd64.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=294c0b05dff4f368512449de7268e3f06de679a9343e9885044adc702865080b  node_exporter-1.1.2.linux-ppc64.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=3919266f1dbad5f7e5ce7b4207057fc253a8322f570607cc0f3e73f4a53338e3  node_exporter-1.1.2.darwin-amd64.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=5b0195e203dedd3a8973cd1894a55097554a4af6d8f4f0614c2c67d6670ea8ae  node_exporter-1.1.2.linux-386.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=d1d201b16d757980db654bb9e448ab0c81ca4c2715243c3fa4305bef5967bd41  node_exporter-1.1.2.linux-ppc64le.tar.gz) 
ok: [monitoring.lodyanyy.ru -> localhost] => (item=8c1f6a317457a658e0ae68ad710f6b4098db2cad10204649b51e3c043aa3e70d  node_exporter-1.1.2.linux-amd64.tar.gz)
skipping: [monitoring.lodyanyy.ru] => (item=eb5e7d16f18bb3272d0d832986fc8ac6cb0b6c42d487c94e15dabb10feae8e04  node_exporter-1.1.2.linux-arm64.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=6007420f425d08626c05de2dbe0e8bb785a16bba1b02c01cb06d37d7fab3bc97  node_exporter-1.1.2.linux-s390x.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=41892e451e80160491a1cc7bbe6bccd6cb842ae8340e1bc6e32f72cefb1aee80  node_exporter-1.1.2.linux-armv5.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=0596e9c1cc358e6fcc60cb83f0d1ba9a37ccee11eca035429c9791c0beb04389  node_exporter-1.1.2.netbsd-386.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=1cc1bf4cacb84d6c228d9ce8045b5b00b73afd954046f7b2add428a04d14daee  node_exporter-1.1.2.linux-armv6.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=a9fe816eb7b976b1587d6d654c437f7d78349f70686fa22ae33e94fe84281af2  node_exporter-1.1.2.linux-armv7.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=46c964efd336f0e35f62c739ce9edf5409911e7652604e411c9b684eb9c48386  node_exporter-1.1.2.netbsd-amd64.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=a99ab2cdc62db25ff01d184e21ad433e3949cd791fc2c80b6bacc6b90d5a62c2  node_exporter-1.1.2.linux-mips.tar.gz) 
skipping: [gitlab.lodyanyy.ru] => (item=d81f86f57a4ed167a4062aa47f8a70b35c146c86bc8e40924c9d1fc3644ec8e6  node_exporter-1.1.2.openbsd-amd64.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=22d9c2a5363502c79e0645ba02eafd9561b33d1e0e819ce4df3fcf7dc96e3792  node_exporter-1.1.2.linux-mips64.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=a66b70690c3c4fff953905a041c74834f96be85a806e74a1cc925e607ef50a26  node_exporter-1.1.2.linux-mips64le.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=f7fba791cbc758b021d0e9a2400c82d1f29337e568ab00edc84b053ca467ea3c  node_exporter-1.1.2.linux-mipsle.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=294c0b05dff4f368512449de7268e3f06de679a9343e9885044adc702865080b  node_exporter-1.1.2.linux-ppc64.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=d1d201b16d757980db654bb9e448ab0c81ca4c2715243c3fa4305bef5967bd41  node_exporter-1.1.2.linux-ppc64le.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=6007420f425d08626c05de2dbe0e8bb785a16bba1b02c01cb06d37d7fab3bc97  node_exporter-1.1.2.linux-s390x.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=0596e9c1cc358e6fcc60cb83f0d1ba9a37ccee11eca035429c9791c0beb04389  node_exporter-1.1.2.netbsd-386.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=46c964efd336f0e35f62c739ce9edf5409911e7652604e411c9b684eb9c48386  node_exporter-1.1.2.netbsd-amd64.tar.gz) 
skipping: [monitoring.lodyanyy.ru] => (item=d81f86f57a4ed167a4062aa47f8a70b35c146c86bc8e40924c9d1fc3644ec8e6  node_exporter-1.1.2.openbsd-amd64.tar.gz) 

TASK [node_exporter : Create the node_exporter group] *****************************************************************************************************************
changed: [gitlab.lodyanyy.ru]
changed: [runner.lodyanyy.ru]
changed: [app.lodyanyy.ru]
changed: [db01.lodyanyy.ru]
changed: [db02.lodyanyy.ru]
changed: [monitoring.lodyanyy.ru]

TASK [node_exporter : Create the node_exporter user] ******************************************************************************************************************
changed: [db02.lodyanyy.ru]
changed: [runner.lodyanyy.ru]
changed: [db01.lodyanyy.ru]
changed: [app.lodyanyy.ru]
changed: [gitlab.lodyanyy.ru]
changed: [monitoring.lodyanyy.ru]

TASK [node_exporter : Download node_exporter binary to local folder] **************************************************************************************************
ok: [db01.lodyanyy.ru -> localhost]
ok: [gitlab.lodyanyy.ru -> localhost]
ok: [db02.lodyanyy.ru -> localhost]
ok: [app.lodyanyy.ru -> localhost]
ok: [runner.lodyanyy.ru -> localhost]
ok: [monitoring.lodyanyy.ru -> localhost]

TASK [node_exporter : Unpack node_exporter binary] ********************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Propagate node_exporter binaries] ***************************************************************************************************************
changed: [app.lodyanyy.ru]
changed: [db02.lodyanyy.ru]
changed: [runner.lodyanyy.ru]
changed: [gitlab.lodyanyy.ru]
changed: [db01.lodyanyy.ru]
changed: [monitoring.lodyanyy.ru]

TASK [node_exporter : propagate locally distributed node_exporter binary] *********************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Install selinux python packages [RHEL]] *********************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Install selinux python packages [Fedora]] *******************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Install selinux python packages [clearlinux]] ***************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Copy the node_exporter systemd service file] ****************************************************************************************************
changed: [db02.lodyanyy.ru]
changed: [app.lodyanyy.ru]
changed: [runner.lodyanyy.ru]
changed: [db01.lodyanyy.ru]
changed: [gitlab.lodyanyy.ru]
changed: [monitoring.lodyanyy.ru]

TASK [node_exporter : Create node_exporter config directory] **********************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Copy the node_exporter config file] *************************************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Create textfile collector dir] ******************************************************************************************************************
changed: [db02.lodyanyy.ru]
changed: [gitlab.lodyanyy.ru]
changed: [app.lodyanyy.ru]
changed: [db01.lodyanyy.ru]
changed: [runner.lodyanyy.ru]
changed: [monitoring.lodyanyy.ru]

TASK [node_exporter : Allow node_exporter port in SELinux on RedHat OS family] ****************************************************************************************
skipping: [db01.lodyanyy.ru]
skipping: [db02.lodyanyy.ru]
skipping: [app.lodyanyy.ru]
skipping: [gitlab.lodyanyy.ru]
skipping: [runner.lodyanyy.ru]
skipping: [monitoring.lodyanyy.ru]

TASK [node_exporter : Ensure Node Exporter is enabled on boot] ********************************************************************************************************
changed: [runner.lodyanyy.ru]
changed: [db01.lodyanyy.ru]
changed: [app.lodyanyy.ru]
changed: [db02.lodyanyy.ru]
changed: [gitlab.lodyanyy.ru]
changed: [monitoring.lodyanyy.ru]

RUNNING HANDLER [node_exporter : restart node_exporter] ***************************************************************************************************************
changed: [runner.lodyanyy.ru]
changed: [app.lodyanyy.ru]
changed: [gitlab.lodyanyy.ru]
changed: [db02.lodyanyy.ru]
changed: [db01.lodyanyy.ru]
changed: [monitoring.lodyanyy.ru]

PLAY RECAP ************************************************************************************************************************************************************
app.lodyanyy.ru            : ok=16   changed=8    unreachable=0    failed=0    skipped=14   rescued=0    ignored=0   
db01.lodyanyy.ru           : ok=17   changed=8    unreachable=0    failed=0    skipped=16   rescued=0    ignored=0   
db02.lodyanyy.ru           : ok=16   changed=8    unreachable=0    failed=0    skipped=14   rescued=0    ignored=0   
gitlab.lodyanyy.ru         : ok=16   changed=8    unreachable=0    failed=0    skipped=14   rescued=0    ignored=0   
monitoring.lodyanyy.ru     : ok=16   changed=8    unreachable=0    failed=0    skipped=14   rescued=0    ignored=0   
runner.lodyanyy.ru         : ok=16   changed=8    unreachable=0    failed=0    skipped=14   rescued=0    ignored=0  
```
</details>

<details>
<summary> ansible-playbook monitoring.yml -i hosts </summary> 

```bash
ubuntu@lodyanyynote:~/netology/diplom/ansible$ ansible-playbook monitoring.yml -i hosts

PLAY [monitoring] *****************************************************************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************************************************************
ok: [monitoring.lodyanyy.ru]

TASK [update : Update apt repo and cache on all Debian/Ubuntu boxes] **************************************************************************************************
ok: [monitoring.lodyanyy.ru]

TASK [monitoring : Prepare For Install Prometheus] ********************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/monitoring/tasks/prepare.yml for monitoring.lodyanyy.ru

TASK [monitoring : Allow Ports] ***************************************************************************************************************************************
skipping: [monitoring.lodyanyy.ru] => (item=9090/tcp) 
skipping: [monitoring.lodyanyy.ru] => (item=9093/tcp) 
skipping: [monitoring.lodyanyy.ru] => (item=9094/tcp) 
skipping: [monitoring.lodyanyy.ru] => (item=9100/tcp) 
skipping: [monitoring.lodyanyy.ru] => (item=9094/udp) 

TASK [monitoring : Disable SELinux] ***********************************************************************************************************************************
skipping: [monitoring.lodyanyy.ru]

TASK [monitoring : Stop SELinux] **************************************************************************************************************************************
skipping: [monitoring.lodyanyy.ru]

TASK [monitoring : Allow TCP Ports] ***********************************************************************************************************************************
changed: [monitoring.lodyanyy.ru] => (item=9090)
changed: [monitoring.lodyanyy.ru] => (item=9093)
changed: [monitoring.lodyanyy.ru] => (item=9094)
changed: [monitoring.lodyanyy.ru] => (item=9100)

TASK [monitoring : Allow UDP Ports] ***********************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Install Prometheus] ********************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/monitoring/tasks/install_prometheus.yml for monitoring.lodyanyy.ru

TASK [monitoring : Create User prometheus] ****************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Create directories for prometheus] *****************************************************************************************************************
changed: [monitoring.lodyanyy.ru] => (item=/tmp/prometheus)
changed: [monitoring.lodyanyy.ru] => (item=/etc/prometheus)
changed: [monitoring.lodyanyy.ru] => (item=/var/lib/prometheus)

TASK [monitoring : Download And Unzipped Prometheus] ******************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Copy Bin Files From Unzipped to Prometheus] ********************************************************************************************************
changed: [monitoring.lodyanyy.ru] => (item=prometheus)
changed: [monitoring.lodyanyy.ru] => (item=promtool)

TASK [monitoring : Copy Conf Files From Unzipped to Prometheus] *******************************************************************************************************
changed: [monitoring.lodyanyy.ru] => (item=console_libraries)
changed: [monitoring.lodyanyy.ru] => (item=consoles)
changed: [monitoring.lodyanyy.ru] => (item=prometheus.yml)

TASK [monitoring : Create File for Prometheus Systemd] ****************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : copy config] ***************************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : copy alert] ****************************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Systemctl Prometheus Start] ************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Install Alertmanager] ******************************************************************************************************************************
included: /home/ubuntu/netology/diplom/ansible/roles/monitoring/tasks/install_alertmanager.yml for monitoring.lodyanyy.ru

TASK [monitoring : Create User Alertmanager] **************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Create Directories For Alertmanager] ***************************************************************************************************************
changed: [monitoring.lodyanyy.ru] => (item=/tmp/alertmanager)
changed: [monitoring.lodyanyy.ru] => (item=/etc/alertmanager)
changed: [monitoring.lodyanyy.ru] => (item=/var/lib/prometheus/alertmanager)

TASK [monitoring : Download And Unzipped Alertmanager] ****************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Copy Bin Files From Unzipped to Alertmanager] ******************************************************************************************************
changed: [monitoring.lodyanyy.ru] => (item=alertmanager)
changed: [monitoring.lodyanyy.ru] => (item=amtool)

TASK [monitoring : Copy Conf File From Unzipped to Alertmanager] ******************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Create File for Alertmanager Systemd] **************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [monitoring : Systemctl Alertmanager Start] **********************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [grafana : Allow Ports] ******************************************************************************************************************************************
skipping: [monitoring.lodyanyy.ru]

TASK [grafana : Disable SELinux] **************************************************************************************************************************************
skipping: [monitoring.lodyanyy.ru]

TASK [grafana : Stop SELinux] *****************************************************************************************************************************************
skipping: [monitoring.lodyanyy.ru]

TASK [grafana : Add Repository] ***************************************************************************************************************************************
skipping: [monitoring.lodyanyy.ru]

TASK [grafana : Install Grafana on RedHat Family] *********************************************************************************************************************
skipping: [monitoring.lodyanyy.ru]

TASK [grafana : Allow TCP Ports] **************************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [grafana : Import Grafana Apt Key] *******************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [grafana : Add APT Repository] ***********************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

TASK [grafana : Install Grafana on Debian Family] *********************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

RUNNING HANDLER [monitoring : systemd reload] *************************************************************************************************************************
ok: [monitoring.lodyanyy.ru]

RUNNING HANDLER [grafana : grafana systemd] ***************************************************************************************************************************
changed: [monitoring.lodyanyy.ru]

PLAY RECAP ************************************************************************************************************************************************************
monitoring.lodyanyy.ru     : ok=29   changed=23   unreachable=0    failed=0    skipped=8    rescued=0    ignored=0 
```
</details>

Заходим на grafana.lodyanyy.ru логин/пароль admin/admin и настраиваем data source prometheus:
  
![](https://user-images.githubusercontent.com/87534423/195178442-48ef3033-bfb5-4e91-9309-5c73dc16e13e.jpg)
  
Импортируем шаблоны дашбордов для графаны:
  
![](https://user-images.githubusercontent.com/87534423/195181214-1fb08ce1-6f49-4cd8-9a63-8485e924be30.jpg)

Алертменеджер:
  
![](https://user-images.githubusercontent.com/87534423/195181356-5138ab28-536a-46ca-9a19-3ee331ad9d6d.jpg)
  
Прометеус:
  
![](https://user-images.githubusercontent.com/87534423/195181496-88609563-8cf5-4731-b451-00ad26e817f9.jpg)
![](https://user-images.githubusercontent.com/87534423/195181548-7cd4a72d-3ec3-49ee-8654-414515565444.jpg)

Репозиторий с terraform и c ansible

