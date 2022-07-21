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

resource "yandex_resourcemanager_folder_iam_binding" "admin-account-iam" {
  folder_id   = "b1gem8suj95s5qrc1va1"
  role        = "editor"
  members     = [
    "serviceAccount:ajepare9k00f1qq8pu83",
  ]
}

resource "yandex_storage_bucket" "bucket-lodyanyy-netology" {
  access_key = "YCAJEKjJBjqHd_5QuEuia0HQZ"
  bucket = "bucket-lodyanyy-netology"
}
