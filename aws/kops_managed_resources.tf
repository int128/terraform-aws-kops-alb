# VPC for the Kubernetes cluster
data "aws_vpc" "kops_vpc" {
  tags {
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

# Subnets for the Kubernetes cluster
data "aws_subnet_ids" "kops_subnets" {
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
}

# Auto Scaling Group for the Kubernetes nodes
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

# Security Group for the Kubernetes nodes
data "aws_security_group" "nodes" {
  tags {
    Name = "nodes.${var.kops_cluster_name}"
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

# Route53 Hosted Zone for the Kubernetes cluster
data "aws_route53_zone" "kops_zone" {
  name = "${var.kops_cluster_name}."
}

# Certificate for the wildcard domain
data "aws_acm_certificate" "nodes_alb" {
  domain = "*.${var.kops_cluster_name}"
}
