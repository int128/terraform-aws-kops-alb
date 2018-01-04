terraform {
  backend "s3" {
    #bucket = ""
    #key = "terraform.tfstate"
    #region = "us-west-2"
  }
}

provider "aws" {
  #region = "us-west-2"
}

variable "kops_cluster_name" {
  type = "string"
  description = "Kubernetes Cluster Name"
  # default = "kops.example.com"
}

locals {
  # ALB safe name of kops_cluster_name
  kops_cluster_name_safe = "${replace("${var.kops_cluster_name}", "/[._]/", "-")}"
}
