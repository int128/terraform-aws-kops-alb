resource "aws_lb" "nodes_alb" {
  name = "alb-nodes-${local.kops_cluster_name_safe}"
  load_balancer_type = "application"
  internal = false
  idle_timeout = 180
  subnets = ["${data.aws_subnet_ids.kops_vpc_subnets.ids}"]
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
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "alb.nodes.${var.kops_cluster_name}"
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

# Security Group for Kubernetes nodes
data "aws_security_group" "nodes" {
  tags {
    Name = "nodes.${var.kops_cluster_name}"
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

data "aws_subnet_ids" "kops_vpc_subnets" {
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
}
