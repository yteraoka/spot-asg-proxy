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

