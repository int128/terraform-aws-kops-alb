## External ALB for Kubernetes services.

resource "aws_lb" "alb_external" {
  name               = "alb-ext-${local.alb_name_hash}"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 180
  subnets            = ["${data.aws_subnet_ids.kops_subnets.ids}"]
  security_groups    = ["${aws_security_group.alb_external.id}"]

  tags {
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

resource "aws_security_group" "alb_external" {
  name        = "alb.ext.nodes.${var.kops_cluster_name}"
  description = "Security group for external ALB"
  vpc_id      = "${data.aws_vpc.kops_vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.alb_external_allow_ip}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

resource "aws_security_group_rule" "alb_external" {
  description              = "Allow from external ALB"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.alb_external.id}"
  security_group_id        = "${data.aws_security_group.kops_nodes.id}"
}

resource "aws_lb_listener" "alb_external" {
  load_balancer_arn = "${aws_lb.alb_external.arn}"
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = "${data.aws_acm_certificate.service.arn}"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    target_group_arn = "${aws_lb_target_group.alb_external.arn}"
    type             = "forward"
  }
}

resource "aws_lb_target_group" "alb_external" {
  name     = "alb-ext-${local.alb_name_hash}"
  port     = 30080
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.kops_vpc.id}"

  health_check {
    path = "/healthz"
  }

  tags {
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

resource "aws_autoscaling_attachment" "alb_external" {
  autoscaling_group_name = "${join(",", data.aws_autoscaling_groups.kops_nodes.names)}"
  alb_target_group_arn   = "${aws_lb_target_group.alb_external.arn}"
}
