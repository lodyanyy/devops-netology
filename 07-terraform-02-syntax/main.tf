provider "yandex" {
  cloud_id  = "b1gt0lvva0m38u41d9e3"
  folder_id = "b1gem8suj95s5qrc1va1"
  zone      = "ru-central1-a"
}

resource "yandex_compute_image" "image" {
  family = "centos-8"
}

resource "yandex_compute_instance" "vm1" {
  name                      = "vm1"
  zone                      = "ru-central1-a"
  hostname                  = "vm1.netology.cloud"
  allow_stopping_for_update = true

  resources {
    cores  = 1
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id    = "${yandex_compute_image.image.id}"
      name        = "root-vm1"
      type        = "network-nvme"
      size        = "30"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.default.id}"
    nat       = true
  }

  metadata = {
    ssh-keys = "centos:${file("~/.ssh/id_rsa.pub")}"
  }

}
