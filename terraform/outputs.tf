output "cloudfront_url" {
  value = "https://${var.url_prefix}.${var.domain_name}"
}

output "cdn_distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}