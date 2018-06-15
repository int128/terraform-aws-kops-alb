## References to self/kops managed resources.

data "aws_availability_zones" "available" {}

##
## SELF MANAGED RESOURCES
##

# Route53 Hosted Zone of the domain for services
data "aws_route53_zone" "service" {
  name = "${var.alb_external_domain_name}."
}

# Certificate of the domain for services
data "aws_acm_certificate" "service" {
  domain = "*.${var.alb_external_domain_name}"
}

##
## KOPS MANAGED RESOURCES
##

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
data "aws_autoscaling_groups" "kops_nodes" {
  filter {
    name   = "key"
    values = ["Name"]
  }

  filter {
    name   = "value"
    values = ["nodes.${var.kops_cluster_name}"]
  }
}

# Security Group for the Kubernetes masters
data "aws_security_group" "kops_masters" {
  tags {
    Name              = "masters.${var.kops_cluster_name}"
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}

# Security Group for the Kubernetes nodes
data "aws_security_group" "kops_nodes" {
  tags {
    Name              = "nodes.${var.kops_cluster_name}"
    KubernetesCluster = "${var.kops_cluster_name}"
  }
}
