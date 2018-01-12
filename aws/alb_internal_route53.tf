# Route53 DNS record for services.
# This is needed if the security group of the external ALB is not open.

resource "aws_route53_zone" "alb_internal" {
  count = "${var.alb_internal_enabled}"
  name = "${var.alb_external_domain_name}"
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
  tags {
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

resource "aws_route53_record" "alb_internal" {
  count = "${var.alb_internal_enabled}"
  zone_id = "${aws_route53_zone.alb_internal.zone_id}"
  name = "*.${var.alb_external_domain_name}"
  type = "A"
  alias {
    name = "${aws_lb.alb_internal.dns_name}"
    zone_id = "${aws_lb.alb_internal.zone_id}"
    evaluate_target_health = false
  }
}
