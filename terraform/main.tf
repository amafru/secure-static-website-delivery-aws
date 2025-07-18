terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket  = "secure-static-webapp-tfstate"
    key     = "dev/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = true
  }
}

# Verify that your hosted zone exists on AWS
data "aws_route53_zone" "hosted_zone" {
  name         = var.hosted_zone
  private_zone = false
}

# Get AWS account ID for the Current User (will be used later)
data "aws_caller_identity" "current" {}

# Retrieve certificate details from ACM
data "aws_acm_certificate" "acm_cert" {
  domain   = "*.${var.domain_name}"
  statuses = ["ISSUED"]
  most_recent = true
}

locals {
  cloudfront_s3_origin_id = "${var.web_assets_bucket}-s3-origin"
}

# Create s3 bucket for storing website assets
resource "aws_s3_bucket" "website_assets_bucket" {
  bucket = var.web_assets_bucket

  tags = {
    Name = "Secure static website bucket"
  }
}

# Configure the s3 bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "config_s3_bucket_as_web_host" {
  bucket = aws_s3_bucket.website_assets_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Turn on Block-Public-Access for the bucket and it's resources
resource "aws_s3_bucket_public_access_block" "block_all" {
  bucket                  = aws_s3_bucket.website_assets_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket policy for secure CloudFront access via OAC
resource "aws_s3_bucket_policy" "cloudfront_s3_access_policy" {
  bucket = aws_s3_bucket.website_assets_bucket.id

  policy = jsonencode({
    Version = "2008-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          "Service" : "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_assets_bucket}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"
          }
        }
      }
    ]
  })
}

# OAC for CloudFront
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-s3-${var.web_assets_bucket}"
  description                       = "OAC for CloudFront to access website S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {

  origin {
    domain_name = aws_s3_bucket.website_assets_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id   = local.cloudfront_s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for secure static website"
  default_root_object = "index.html"

  aliases = ["simple-static-website.${var.domain_name}"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.cloudfront_s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200" # Includes Edge Locations in US, Canada & Europe only

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = "Live"
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.acm_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Route53 record pointing to CloudFront
resource "aws_route53_record" "dns_alias_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${var.url_prefix}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
