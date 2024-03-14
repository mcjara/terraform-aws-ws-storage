output "logs_bucket" {
  value = aws_s3_bucket.logs_bucket
}

output "assets_bucket" {
  value = aws_s3_bucket.assets_bucket
}

output "assets_bucket_instance_profile" {
  value = aws_iam_instance_profile.ec2_profile
}