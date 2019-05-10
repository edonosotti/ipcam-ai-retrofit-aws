# Create a bucket to temporarily store messages for processing
resource "aws_s3_bucket" "bucket" {
  bucket = "${replace(var.solution_tag, "_", "-")}"
  acl    = "private"

  lifecycle_rule {
    id      = "${var.solution_tag}_bucket_rule"
    enabled = true

    expiration {
      days = 1
    }
  }

  tags = {
    Name = "${var.solution_tag}"
  }
}

# Set permissions for SES and API Gateway
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid = "AllowLambdaRWSESAPIGateway"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    principals {
      type        = "Service"
      identifiers = [
        "ses.amazonaws.com",
        "apigateway.amazonaws.com"
      ]
    }

    condition {
      test = "StringEquals"
      variable = "aws:Referer"
      values = ["${data.aws_caller_identity.current.account_id}"]
    }

    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }

  depends_on = ["aws_s3_bucket.bucket"]
}

# Apply the policy to the bucket
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = "${aws_s3_bucket.bucket.id}"
  policy = "${data.aws_iam_policy_document.bucket_policy.json}"

  depends_on = [
    "aws_s3_bucket.bucket",
    "data.aws_iam_policy_document.bucket_policy"
  ]
}
