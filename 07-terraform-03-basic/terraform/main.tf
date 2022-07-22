terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  cloud_id  = "b1gt0lvva0m38u41d9e3"
  folder_id = "b1gem8suj95s5qrc1va1"
  zone      = "ru-central1-a"
}

locals {
  instance_name = "${terraform.workspace}-instance"
}

resource "yandex_compute_image" "image" {
  source_family = "centos-8"
}

resource "yandex_compute_instance" "vm" {
  count = terraform.workspace == "prod" ? 2 : 1
  name                      = local.instance_name
  allow_stopping_for_update = true

  resources {
    cores  = terraform.workspace == "prod" ? 4 : 2
    memory = terraform.workspace == "prod" ? 4 : 2
  }
  
 boot_disk {
    initialize_params {
      image_id    = "${yandex_compute_image.image.id}"
      name        = "root-${local.instance_name}"
      type        = "network-nvme"
      size        = "30"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network-1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name = "subnet-1"
  zone = "ru-central1-a"
  network_id = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["192.168.101.0/24"]
}

resource "yandex_resourcemanager_folder_iam_binding" "admin-account-iam" {
  folder_id   = "b1gem8suj95s5qrc1va1"
  role        = "editor"
  members     = [
    "serviceAccount:ajepare9k00f1qq8pu83",
  ]
}

resource "yandex_storage_bucket" "bucket-lodyanyy-netology" {
  access_key = "YCAJEKjJBjqHd_5QuEuia0HQZ"
  secret_key = "YCPEOk8D70lYdmt1jUX6gsdvrdvjbrZ7yXRc2zoEB7HHX"
  bucket = "bucket-lodyanyy-netology"
}
