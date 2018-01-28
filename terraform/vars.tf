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

variable "alb_external_domain_name" {
  type = "string"
  description = "Domain Name for external ALB"
  # default = "dev.example.com"
}

variable "alb_external_allow_ip" {
  type = "list"
  description = "Allow IP addresses for external ALB"
  default = [
    "0.0.0.0/0",  # all
  ]
}

variable "alb_internal_enabled" {
  type = "string"
  description = "Enable internal ALB (needed if external ALB is not open)"
  default = false
}

locals {
  # Hash of kops_cluster_name and alb_external_domain_name
  alb_name_hash = "${substr(sha256("${var.kops_cluster_name}/${var.alb_external_domain_name}"), 0, 16)}"
}
