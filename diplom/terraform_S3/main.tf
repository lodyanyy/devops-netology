provider "yandex" {
  token     = var.YC_TOKEN
  cloud_id  = var.YC_CLOUD_ID
  folder_id = var.YC_FOLDER_ID
  zone      = var.YC_ZONE_DEFAULT
}

resource "yandex_storage_bucket" "diplom" {
  access_key = var.YC_ACCESS_KEY
  secret_key = var.YC_SECRET_KEY
  bucket = "lodyanyy-bucket"
}

