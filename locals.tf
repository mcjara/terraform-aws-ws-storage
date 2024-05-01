resource "random_uuid" "logs_s3" {
}

resource "random_uuid" "assets_s3" {
}

locals {
  logs_bucket_name   = lower("${var.instance_name}-${random_uuid.logs_s3.result}")
  assets_bucket_name = lower("${var.instance_name}-${random_uuid.assets_s3.result}")
}