terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = "my_token_is_here"
  cloud_id  = "my_cloud_id"
  folder_id = "my_folder_id"
}
