# S3 Buckets

resource "aws_s3_bucket" "logs_bucket" {
  bucket        = local.logs_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "logs_bucket" {
  bucket = aws_s3_bucket.logs_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "assets_bucket" {
  bucket        = local.assets_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "assets_bucket" {
  bucket = aws_s3_bucket.assets_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

# IAM Policies

## AWS Regions added after Jakarta 2022

variable "modern_regions" {
  default = ["ap-south-2", "ap-southeast-4", "ca-west-1", "eu-south-2", "eu-central-2", "il-central-1", "me-central-1"]
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {
}

locals {
  aws_region    = data.aws_region.current.name
  aws_account_id  = data.aws_caller_identity.current.account_id
  modern_region = contains(var.modern_regions, local.aws_region)
}

## Understand if AWS_REGION is an original one or not. If not, extract root elb username.

data "aws_elb_service_account" "root" {
  count = local.modern_region ? 0 : 1
}

/*

data "aws_iam_policy_document" "legacy_s3_policy" {
  count = local.modern_region ? 0 : 1

  statement {
    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.root[0].arn}"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.logs_bucket.arn}/alb/access/*",
      "${aws_s3_bucket.logs_bucket.arn}/alb/connections/*"
    ]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.logs_bucket.arn}/alb/access/*",
      "${aws_s3_bucket.logs_bucket.arn}/alb/connections/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]
    resources = ["${aws_s3_bucket.logs_bucket.arn}"]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["s3:*"]
    resources = [
      "${aws_s3_bucket.logs_bucket.arn}",
      "${aws_s3_bucket.logs_bucket.arn}/*"
    ]

    condition {
      test     = "NotIpAddress"
      variable = "aws:SourceIp"
      values   = var.source_ip_range
    }

    effect = "Deny"
  }
}

resource "aws_s3_bucket_policy" "logs_bucket-legacy" {
  count  = local.modern_region ? 0 : 1
  bucket = aws_s3_bucket.logs_bucket.id
  policy = data.aws_iam_policy_document.legacy_s3_policy[0].json
}

*/

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


/*

data "aws_iam_policy_document" "modern_s3_policy" {
  count = local.modern_region ? 1 : 0

  statement {
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "arn:aws:s3:::${local.logs_bucket_name}/alb/access/AWSLogs/${local.aws_region}/*",
      "arn:aws:s3:::${local.logs_bucket_name}/alb/connections/AWSLogs/${local.aws_region}/*"
    ]
  }

  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject", "s3:GetBucketAcl"]
    resources = [
      "arn:aws:s3:::${local.logs_bucket_name}/alb/access/*",
      "arn:aws:s3:::${local.logs_bucket_name}/alb/connections/*",
      "arn:aws:s3:::${local.logs_bucket_name}"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      "${aws_s3_bucket.logs_bucket.arn}",
      "${aws_s3_bucket.logs_bucket.arn}/*"
    ]

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.source_ip_range
    }

    effect = "Allow"
  }
}

resource "aws_s3_bucket_policy" "logs_bucket-modern" {
  count  = local.modern_region ? 1 : 0
  bucket = aws_s3_bucket.logs_bucket.id
  policy = data.aws_iam_policy_document.modern_s3_policy[0].json
}

*/

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
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/access/AWSLogs/${local.aws_account_id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logdelivery.elasticloadbalancing.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${local.logs_bucket_name}/alb/connections/AWSLogs/${local.aws_account_id}/*"
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