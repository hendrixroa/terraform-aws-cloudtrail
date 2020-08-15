data "aws_caller_identity" "current" {
  count = var.enabled == 1 ? 1 : 0
}

data "aws_region" "current" {
  count = var.enabled == 1 ? 1 : 0
}

resource "aws_cloudtrail" "main" {
  count = var.enabled == 1 ? 1 : 0

  name                          = "${var.name}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.main[count.index].id
  s3_key_prefix                 = var.name
  include_global_service_events = true
  kms_key_id                    = aws_kms_key.main[count.index].arn
  enable_logging                = true
  enable_log_file_validation    = true
  is_multi_region_trail         = true

  depends_on = [
    aws_s3_bucket.main
  ]
}

resource "aws_s3_bucket" "main" {
  count = var.enabled == 1 ? 1 : 0

  bucket = "${var.name}-${data.aws_caller_identity.current[count.index].account_id}-cloudtrail"
  acl    = "private"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.name}-${data.aws_caller_identity.current[count.index].account_id}-cloudtrail"
        },
        {
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.name}-${data.aws_caller_identity.current[count.index].account_id}-cloudtrail/${var.name}/AWSLogs/${data.aws_caller_identity.current[count.index].account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  count = var.enabled == 1 ? 1 : 0

  bucket = aws_s3_bucket.main[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "main" {
  count = var.enabled == 1 ? 1 : 0

  description = "KMS key for cloudtrail"

  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement" : [ {
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "arn:aws:iam::${data.aws_caller_identity.current[count.index].account_id}:root"
      },
      "Action" : "kms:*",
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

  enable_key_rotation = true
}

resource "aws_kms_alias" "main" {
  count = var.enabled == 1 ? 1 : 0

  name          = "alias/${var.name}-cloudtrail"
  target_key_id = aws_kms_key.main[count.index].key_id
}