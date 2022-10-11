variable "YC_CLOUD_ID" {
  default = "b1gt0lvva0m38u41d9e3"
}

variable "YC_FOLDER_ID" {
  default = "b1ga4bvbtmsib2460tvl"
}

variable "YC_ZONE_DEFAULT" {
  default = "ru-central1-a"
}

variable "YC_TOKEN" { 
  type = string 
  sensitive = true
}

variable "YC_ACCESS_KEY" { 
  type = string 
  sensitive = true
}

variable "YC_SECRET_KEY" { 
  type = string 
  sensitive = true
}
