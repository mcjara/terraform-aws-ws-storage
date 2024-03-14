# S3 Buckets

resource "aws_s3_bucket" "logs_bucket" {
  bucket        = local.logs_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket" "assets_bucket" {
  bucket        = local.assets_bucket_name
  force_destroy = true
}

# IAM Policies

## AWS Regions added after Jakarta 2022

variable "modern_regions" {
  default = ["ap-south-2", "ap-southeast-4", "ca-west-1", "eu-south-2", "eu-central-2", "il-central-1", "me-central-1"]
}

data "aws_region" "current" {}

locals {
  aws_region    = data.aws_region.current.name
  modern_region = contains(var.modern_regions, local.aws_region)
}

## Understand if AWS_REGION is an original one or not. If not, extract root elb username.

data "aws_elb_service_account" "root" {
  count = local.modern_region ? 0 : 1
}

## Define Logs S3 Bucket Policy

resource "aws_s3_bucket_policy" "logs_bucket-legacy" {
  count  = local.modern_region ? 0 : 1
  bucket = aws_s3_bucket.logs_bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.root[0].arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/access/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.root[0].arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/connections/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/access/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/connections/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}"
    }
  ]
}
    POLICY
}

resource "aws_s3_bucket_policy" "logs_bucket-modern" {
  count  = local.modern_region ? 1 : 0
  bucket = aws_s3_bucket.logs_bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/access/AWSLogs/${local.aws_region}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/connections/AWSLogs/${local.aws_region}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/access/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/connections/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}"
    }
  ]
}
    POLICY
}

## Define Assets S3 Bucket Policy

resource "aws_iam_role" "allow_ec2" {
  name = "${local.assets_bucket_name}-allow-ec2"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.assets_bucket_name}-ec2-profile"
  role = aws_iam_role.allow_ec2.name
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name = "${local.assets_bucket_name}-allow-s3-all"
  role = aws_iam_role.allow_ec2.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
                "arn:aws:s3:::${local.assets_bucket_name}",
                "arn:aws:s3:::${local.assets_bucket_name}/*",
                "arn:aws:s3:::${local.logs_bucket_name}",
                "arn:aws:s3:::${local.logs_bucket_name}/*"
            ]
    }
  ]
}
EOF
}