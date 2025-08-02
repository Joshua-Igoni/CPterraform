variable "app_name"   { type = string }
variable "alb_dns_name"   { type = string }
variable "tags"           { type = map(string) }
variable "alb_domain_name" {
  description = "FQDN that CloudFront should forward to (either the ALB DNS name or an alias record you create elsewhere)."
  type        = string
}