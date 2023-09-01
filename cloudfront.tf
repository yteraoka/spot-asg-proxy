resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled = true

  default_root_object = "index.html"

  origin {
    origin_id                = aws_s3_bucket.evidence.id
    domain_name              = aws_s3_bucket.evidence.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_acl.arn

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.evidence.id
    viewer_protocol_policy = "redirect-to-https"
    cached_methods         = ["GET", "HEAD"]
    allowed_methods        = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.append_index_html.arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${local.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "append_index_html" {
  name    = "append-index-html"
  runtime = "cloudfront-js-1.0"
  comment = "Add index.html after the trailing slash."
  publish = true
  code    = file("${path.module}/cloudfront_functions/index.js")
}
