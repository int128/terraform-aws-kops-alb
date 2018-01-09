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
  # default = "example.k8s.local"
}

variable "service_domain_name" {
  type = "string"
  description = "Domain Name for services"
  # default = "dev.example.com"
}

locals {
  # Hash of kops_cluster_name and service_domain_name
  alb_name_hash = "${substr(sha256("${var.kops_cluster_name}/${var.service_domain_name}"), 0, 16)}"
}
