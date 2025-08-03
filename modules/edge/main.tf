data "aws_caller_identity" "this" {}



resource "aws_s3_bucket" "static" {
  bucket = "notejam-static-${data.aws_caller_identity.this.account_id}"
  force_destroy = true
}

# Block public access at the bucket level (best practice)
resource "aws_s3_bucket_public_access_block" "static" {
  bucket              = aws_s3_bucket.static.id
  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name = "notejam-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

data "aws_iam_policy_document" "static_bucket" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.static_bucket.json
}

resource "aws_cloudfront_distribution" "main" {
  enabled = true
  price_class = "PriceClass_100"
  aliases     = []           # keep it empty until you have your ACM cert

  origin {
    origin_id   = "alb-origin"
    domain_name = var.alb_domain_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    origin_id   = "s3-static"
    domain_name = aws_s3_bucket.static.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "alb-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET"]
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "s3-static"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD","GET"]
    default_ttl            = 86400
    max_ttl                = 604800
    min_ttl                = 3600
    compress               = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/media/*"
    target_origin_id       = "s3-static"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["HEAD", "GET"]
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }

  # SSL/TLS − for now use CloudFront default certificate
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version        = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  default_root_object = ""
}