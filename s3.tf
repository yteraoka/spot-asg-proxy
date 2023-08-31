resource "aws_s3_bucket" "evidence" {
  bucket = "${local.name}-evidence-${data.aws_caller_identity.current.account_id}"
}

