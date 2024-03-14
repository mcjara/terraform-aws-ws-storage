resource "random_integer" "logs_s3" {
  min = 1000
  max = 9999
}

resource "random_integer" "assets_s3" {
  min = 1000
  max = 9999
}

locals {
  logs_bucket_name   = lower("${var.instance_name}-logs-${random_integer.logs_s3.result}")
  assets_bucket_name = lower("${var.instance_name}-assets-${random_integer.assets_s3.result}")
}