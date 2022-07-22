terraform {
    backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "bucket-lodyanyy-netology"
    region     = "ru-central1"
    key        = "path/terraform.tfstate"
    access_key = "YCAJEKjJBjqHd_5QuEuia0HQZ"
    secret_key = "00000000000"

    skip_region_validation      = true
    skip_credentials_validation = true
  }  
}
