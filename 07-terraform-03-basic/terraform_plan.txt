lodyanyy@lodyanyy:~/netology/07-terraform-03-basic/cloud-terraform$ terraform workspace list        
  default
* prod
  stage

lodyanyy@lodyanyy:~/netology/07-terraform-03-basic/cloud-terraform$ terraform plan 

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # yandex_compute_image.image will be created
  + resource "yandex_compute_image" "image" {
      + created_at      = (known after apply)
      + folder_id       = (known after apply)
      + id              = (known after apply)
      + min_disk_size   = (known after apply)
      + os_type         = (known after apply)
      + pooled          = (known after apply)
      + product_ids     = (known after apply)
      + size            = (known after apply)
      + source_disk     = (known after apply)
      + source_family   = "centos-8"
      + source_image    = (known after apply)
      + source_snapshot = (known after apply)
      + source_url      = (known after apply)
      + status          = (known after apply)
    }

  # yandex_compute_instance.vm[0] will be created
  + resource "yandex_compute_instance" "vm" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                centos:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWktg60+cCz+9XXai8/m9YHoBcVXAMLoC9e7HtnUJxHX5PlUodGm0cv6ltuSlxiaziifiaFUxA8G2oEkfZFjhOsGB3UZoSbKTdJC9KmEHrIMbPnJHWcjgpY9qcXlfP6gtpNfWWGPejQpWF3O/37vMZ6uwr9/iTOlaVzdt5QOHAfVTmlEE2+kSPfyXrDeJwFeV46ANPJnt+36dlKF7+CKNGuXVAJYKYRooSbZ/T6r6ojxmJNKw/GKeciIDHlqt3X7mqiI1sKJOiI+aFOB+DwZlenbxwjA6QVdt8E+C2mzlzQcDEexK65hqbZSCkmBKOuyOhTAQwqCfz8MDsYkV7xqTqEcX4KkQJLk0bYiRPJyI4GuneZkus0c5jUIJr+4Ykp7+4mpln7ix2e+36aFkUrEJmGt6r0+FIv9wPwtACBeZqWTHJQlLd91kfLvj3uKarhlC5Zu4NT9q5uorym1dFhvmn30srfZji1QlVzyu2L9jUxGXAs7rYF+GoAtdULToOIQM= lodyanyy@lodyanyy
            EOT
        }
      + name                      = "prod-instance"
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
              + image_id    = (known after apply)
              + name        = "root-prod-instance"
              + size        = 30
              + snapshot_id = (known after apply)
              + type        = "network-nvme"
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

  # yandex_compute_instance.vm[1] will be created
  + resource "yandex_compute_instance" "vm" {
      + allow_stopping_for_update = true
      + created_at                = (known after apply)
      + folder_id                 = (known after apply)
      + fqdn                      = (known after apply)
      + hostname                  = (known after apply)
      + id                        = (known after apply)
      + metadata                  = {
          + "ssh-keys" = <<-EOT
                centos:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWktg60+cCz+9XXai8/m9YHoBcVXAMLoC9e7HtnUJxHX5PlUodGm0cv6ltuSlxiaziifiaFUxA8G2oEkfZFjhOsGB3UZoSbKTdJC9KmEHrIMbPnJHWcjgpY9qcXlfP6gtpNfWWGPejQpWF3O/37vMZ6uwr9/iTOlaVzdt5QOHAfVTmlEE2+kSPfyXrDeJwFeV46ANPJnt+36dlKF7+CKNGuXVAJYKYRooSbZ/T6r6ojxmJNKw/GKeciIDHlqt3X7mqiI1sKJOiI+aFOB+DwZlenbxwjA6QVdt8E+C2mzlzQcDEexK65hqbZSCkmBKOuyOhTAQwqCfz8MDsYkV7xqTqEcX4KkQJLk0bYiRPJyI4GuneZkus0c5jUIJr+4Ykp7+4mpln7ix2e+36aFkUrEJmGt6r0+FIv9wPwtACBeZqWTHJQlLd91kfLvj3uKarhlC5Zu4NT9q5uorym1dFhvmn30srfZji1QlVzyu2L9jUxGXAs7rYF+GoAtdULToOIQM= lodyanyy@lodyanyy
            EOT
        }
      + name                      = "prod-instance"
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
              + image_id    = (known after apply)
              + name        = "root-prod-instance"
              + size        = 30
              + snapshot_id = (known after apply)
              + type        = "network-nvme"
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

  # yandex_resourcemanager_folder_iam_binding.admin-account-iam will be created
  + resource "yandex_resourcemanager_folder_iam_binding" "admin-account-iam" {
      + folder_id = "b1gem8suj95s5qrc1va1"
      + id        = (known after apply)
      + members   = [
          + "serviceAccount:ajepare9k00f1qq8pu83",
        ]
      + role      = "editor"
    }

  # yandex_storage_bucket.bucket-lodyanyy-netology will be created
  + resource "yandex_storage_bucket" "bucket-lodyanyy-netology" {
      + access_key            = "YCAJEKjJBjqHd_5QuEuia0HQZ"
      + acl                   = "private"
      + bucket                = "bucket-lodyanyy-netology"
      + bucket_domain_name    = (known after apply)
      + default_storage_class = (known after apply)
      + folder_id             = (known after apply)
      + force_destroy         = false
      + id                    = (known after apply)
      + secret_key            = (sensitive value)
      + website_domain        = (known after apply)
      + website_endpoint      = (known after apply)

      + anonymous_access_flags {
          + list = (known after apply)
          + read = (known after apply)
        }

      + versioning {
          + enabled = (known after apply)
        }
    }

  # yandex_vpc_network.network-1 will be created
  + resource "yandex_vpc_network" "network-1" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "network-1"
      + subnet_ids                = (known after apply)
    }

  # yandex_vpc_subnet.subnet-1 will be created
  + resource "yandex_vpc_subnet" "subnet-1" {
      + created_at     = (known after apply)
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "subnet-1"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "192.168.101.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-a"
    }

Plan: 7 to add, 0 to change, 0 to destroy.
