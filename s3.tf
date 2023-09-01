#trivy:ignore:AVD-AWS-0086 HIGH: No public access block so not blocking public acls
#trivy:ignore:AVD-AWS-0087 HIGH: No public access block so not blocking public policies
#trivy:ignore:AVD-AWS-0088 HIGH: Bucket does not have encryption enabled
#trivy:ignore:AVD-AWS-0089 MEDIUM: Bucket does not have logging enabled
#trivy:ignore:AVD-AWS-0090 MEDIUM: Bucket does not have versioning enabled
#trivy:ignore:AVD-AWS-0091 HIGH: No public access block so not ignoring public acls
#trivy:ignore:AVD-AWS-0093 HIGH: No public access block so not restricting public buckets
#trivy:ignore:AVD-AWS-0094 LOW: Bucket does not have a corresponding public access block
#trivy:ignore:AVD-AWS-0132 HIGH: Bucket does not encrypt data with a customer managed key
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
