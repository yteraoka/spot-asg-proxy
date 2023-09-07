resource "aws_s3_bucket" "evidence" {
  #checkov:skip=CKV2_AWS_62:event 設定は不要
  #checkov:skip=CKV_AWS_18:access log は不要
  #checkov:skip=CKV_AWS_145:kms で暗号化しない
  #checkov:skip=CKV2_AWS_61:lifecycle 設定なし
  #checkov:skip=CKV_AWS_21:versioning 不要
  #checkov:skip=CKV_AWS_144:replication 不要
  #checkov:skip=CKV2_AWS_6:デフォルトで public アクセスは無効になっている
  bucket = "${local.name}-evidence-${data.aws_caller_identity.current.account_id}"
}

# aws_iam_policy_document を使うとインデントの毎回差分が出てしまう
resource "aws_s3_bucket_policy" "evidence" {
  bucket = aws_s3_bucket.evidence.id
  policy = <<-EOT
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "AllowCloudFrontServicePrincipal",
              "Effect": "Allow",
              "Principal": {
                  "Service": "cloudfront.amazonaws.com"
              },
              "Action": "s3:GetObject",
              "Resource": "${aws_s3_bucket.evidence.arn}/*",
              "Condition": {
                  "StringEquals": {
                      "aws:SourceArn": "${aws_cloudfront_distribution.s3_distribution.arn}"
                  }
              }
          }
      ]
  }
  EOT
}
