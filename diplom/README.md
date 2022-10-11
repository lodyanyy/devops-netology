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
