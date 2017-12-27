resource "aws_lb_listener" "nodes" {
  load_balancer_arn = "${aws_lb.nodes_alb.arn}"
  port = 443
  protocol = "HTTPS"
  certificate_arn = "${data.aws_acm_certificate.nodes_alb.arn}"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  default_action {
    target_group_arn = "${aws_lb_target_group.nodes.arn}"
    type = "forward"
  }
}

# Certificate for the wildcard domain
data "aws_acm_certificate" "nodes_alb" {
  domain = "*.${var.kops_cluster_name}"
}

resource "aws_lb_target_group" "nodes" {
  name = "nginx-ingress-${local.kops_cluster_name_safe}"
  port = 30080
  protocol = "HTTP"
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
  health_check {
  }
  tags {
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

resource "aws_autoscaling_attachment" "nodes_alb" {
  autoscaling_group_name = "${join(",", data.aws_autoscaling_groups.nodes.names)}"
  alb_target_group_arn = "${aws_lb_target_group.nodes.arn}"
}

data "aws_autoscaling_groups" "nodes" {
  filter {
    name = "key"
    values = ["Name"]
  }
  filter {
    name = "value"
    values = ["nodes.${var.kops_cluster_name}"]
  }
}
