resource "aws_wafv2_ip_set" "gen2_vpc_egress" {
  provider           = aws.virginia
  name               = "${local.name}-vpc-egress"
  description        = "Gen2 VPC Egress IP set"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.allow_cidrs
}

resource "aws_wafv2_web_acl" "cloudfront_acl" {
  provider    = aws.virginia
  name        = "${local.name}-cloudfront-acl"
  description = "${local.name} CloudFront ACL"
  scope       = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "rule-1"
    priority = 0
    action {
      allow {}
    }
    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.gen2_vpc_egress.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "default"
    sampled_requests_enabled   = false
  }
}
