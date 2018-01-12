# Resources for managed services accessed from Kubernetes nodes.

resource "aws_security_group" "allow_from_k8s_nodes" {
  description = "Security group for managed services accessed from k8s nodes"
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
  ingress {
    description = "Allow from Kubernetes nodes"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${data.aws_security_group.kops_nodes.id}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "allow-from-nodes.${var.kops_cluster_name}"
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

resource "aws_db_subnet_group" "rds_for_k8s_nodes" {
  name = "rds-for-nodes.${var.kops_cluster_name}"
  subnet_ids = ["${data.aws_subnet_ids.kops_subnets.ids}"]
  tags {
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}
