terraform {
  backend "s3" {}
}

provider "aws" {
}

variable "kops_cluster_name" {
  type = "string"
  description = "Kubernetes Cluster Name"
}

locals {
  # ALB safe name of kops_cluster_name
  kops_cluster_name_safe = "${replace("${var.kops_cluster_name}", "/[._]/", "-")}"
}
