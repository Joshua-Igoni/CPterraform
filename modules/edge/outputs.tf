output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.main.domain_name
}
output "static_bucket_name" {
  value = aws_s3_bucket.static.id
}
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}