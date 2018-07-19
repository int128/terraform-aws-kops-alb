## Route53 for the internal ALB.

resource "aws_route53_zone" "alb_internal" {
  count  = "${var.alb_internal_enabled}"
  name   = "${var.kubernetes_ingress_domain}"
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
  tags   = "${map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "owned")}"
}

resource "aws_route53_record" "alb_internal" {
  count   = "${var.alb_internal_enabled}"
  zone_id = "${aws_route53_zone.alb_internal.zone_id}"
  name    = "*.${var.kubernetes_ingress_domain}"
  type    = "A"

  alias {
    name                   = "${aws_lb.alb_internal.dns_name}"
    zone_id                = "${aws_lb.alb_internal.zone_id}"
    evaluate_target_health = false
  }
}
