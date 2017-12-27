resource "aws_route53_record" "alb_nodes" {
  zone_id = "${data.aws_route53_zone.kops_zone.zone_id}"
  name = "*.${var.kops_cluster_name}"
  type = "A"
  alias {
    name = "${aws_lb.nodes_alb.dns_name}"
    zone_id = "${aws_lb.nodes_alb.zone_id}"
    evaluate_target_health = false
  }
}

data "aws_route53_zone" "kops_zone" {
  name = "${var.kops_cluster_name}."
}
