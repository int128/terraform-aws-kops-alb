terraform {
  backend "s3" {
    key = "terraform.tfstate"

    #bucket = ""
    #region = "us-west-2"
  }
}

provider "aws" {
  #region = "us-west-2"
}

variable "kubernetes_cluster_name" {
  type        = "string"
  description = "Kubernetes Cluster Name"

  #default = "example.k8s.local"
}

variable "kubernetes_ingress_domain" {
  type        = "string"
  description = "Domain Name for external ALB"

  #default = "dev.example.com"
}

variable "alb_external_allow_ip" {
  type        = "list"
  description = "Allow IP addresses for external ALB"

  default = [
    "0.0.0.0/0", # all
  ]
}

variable "alb_internal_enabled" {
  type        = "string"
  description = "Enable internal ALB (needed if external ALB is not open)"
  default     = false
}

locals {
  # Hash of kubernetes_cluster_name and kubernetes_ingress_domain
  alb_name_hash = "${substr(sha256("${var.kubernetes_cluster_name}/${var.kubernetes_ingress_domain}"), 0, 16)}"
}
