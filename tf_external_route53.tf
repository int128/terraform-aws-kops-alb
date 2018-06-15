## Route53 for the external ALB.

resource "aws_route53_record" "alb_external" {
  zone_id = "${data.aws_route53_zone.service.zone_id}"
  name    = "*.${var.kubernetes_ingress_domain}"
  type    = "A"

  alias {
    name                   = "${aws_lb.alb_external.dns_name}"
    zone_id                = "${aws_lb.alb_external.zone_id}"
    evaluate_target_health = false
  }
}
