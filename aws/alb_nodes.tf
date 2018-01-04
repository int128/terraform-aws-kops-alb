resource "aws_lb" "nodes_alb" {
  name = "alb-nodes-${local.kops_cluster_name_safe}"
  load_balancer_type = "application"
  internal = false
  idle_timeout = 180
  subnets = ["${data.aws_subnet_ids.kops_subnets.ids}"]
  security_groups = [
    "${aws_security_group.nodes_alb.id}",
    "${data.aws_security_group.nodes.id}"
  ]
  tags {
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

resource "aws_security_group" "nodes_alb" {
  description = "Security Group for ALB"
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
  tags {
    Name = "alb.nodes.${var.kops_cluster_name}"
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

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
