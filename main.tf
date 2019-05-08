## References to self/kops managed resources.

data "aws_availability_zones" "available" {}

##
## SELF MANAGED RESOURCES
##

# Route53 Hosted Zone of the domain for services
data "aws_route53_zone" "service" {
  name = "${var.kubernetes_ingress_domain}."
}

# Certificate of the domain for services
data "aws_acm_certificate" "service" {
  domain = "*.${var.kubernetes_ingress_domain}"
}

##
## KOPS MANAGED RESOURCES
##

# VPC for the Kubernetes cluster
data "aws_vpc" "kops_vpc" {
  tags = "${map("kubernetes.io/cluster/${var.kops_cluster_name}", "owned")}"
}

# Subnets for the Kubernetes cluster
data "aws_subnet_ids" "kops_subnets" {
  vpc_id = "${data.aws_vpc.kops_vpc.id}"
}

# Auto Scaling Group for the Kubernetes nodes
data "aws_autoscaling_groups" "kops_nodes" {
  filter {
    name   = "key"
    values = ["Name"]
  }

  filter {
    name   = "value"
    values = ["${var.kops_ig_nodes_names}"]
  }
}

# Security Group for the Kubernetes masters
data "aws_security_group" "kops_masters" {
  tags {
    Name = "masters.${var.kops_cluster_name}"
  }
}

# Security Group for the Kubernetes nodes
data "aws_security_group" "kops_nodes" {
  tags {
    Name = "nodes.${var.kops_cluster_name}"
  }
}

resource "aws_security_group" "allow_from_k8s_nodes" {
  name        = "allow-from-nodes.${var.kops_cluster_name}"
  description = "Security group for managed services accessed from k8s nodes"
  vpc_id      = "${data.aws_vpc.kops_vpc.id}"
  tags        = "${map("kubernetes.io/cluster/${var.kops_cluster_name}", "owned")}"

  ingress {
    description     = "Allow from Kubernetes nodes"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${data.aws_security_group.kops_nodes.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
