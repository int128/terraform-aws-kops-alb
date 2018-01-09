# Route53 Hosted Zone of the domain for services
data "aws_route53_zone" "service" {
  name = "${var.service_domain_name}."
}

# Certificate of the domain for services
data "aws_acm_certificate" "service" {
  domain = "*.${var.service_domain_name}"
}
