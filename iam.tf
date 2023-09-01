data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = local.name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "profile" {
  name = local.name
  role = aws_iam_role.ec2.name
}

data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

data "aws_iam_policy_document" "s3_reader" {
  statement {
    actions   = ["s3:ListBucket"]
    effect    = "Allow"
    resources = [aws_s3_bucket.evidence.arn]
  }
  statement {
    actions = ["s3:GetObject"]
    effect  = "Allow"
    #trivy:ignore:AVD-AWS-0057 HIGH: IAM policy document uses sensitive action 's3:GetObject' on wildcarded resource
    resources = ["${aws_s3_bucket.evidence.arn}/*"]
  }
  statement {
    actions   = ["ssm:DescribeParameters"]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    effect    = "Allow"
    resources = ["arn:aws:ssm:ap-northeast-1:${data.aws_caller_identity.current.account_id}:parameter/${local.name}/*"]
  }
  statement {
    actions   = ["kms:Decrypt"]
    effect    = "Allow"
    resources = [data.aws_kms_alias.ssm.target_key_arn]
  }
}

resource "aws_iam_policy" "s3_reader" {
  name   = "${local.name}-s3-reader"
  policy = data.aws_iam_policy_document.s3_reader.json
}

resource "aws_iam_role_policy_attachment" "ec2_s3_reader" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.s3_reader.arn
}



#
# GitHub Actions
#

data "aws_iam_policy_document" "s3_writer" {
  statement {
    actions   = ["s3:ListBucket"]
    effect    = "Allow"
    resources = [aws_s3_bucket.evidence.arn]
  }
  statement {
    #trivy:ignore:AVD-AWS-0057 HIGH: IAM policy document uses wildcarded action 's3:*'
    actions = ["s3:*"]
    effect  = "Allow"
    #trivy:ignore:AVD-AWS-0057 HIGH: IAM policy document uses sensitive action 's3:*' on wildcarded resource
    resources = ["${aws_s3_bucket.evidence.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_writer" {
  name   = "${local.name}-s3-writer"
  policy = data.aws_iam_policy_document.s3_writer.json
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_trusted_relationship" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        data.aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:yteraoka/evidence-example:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${local.name}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_trusted_relationship.json
}

resource "aws_iam_role_policy_attachment" "github_actions_s3_writer" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.s3_writer.arn
}
