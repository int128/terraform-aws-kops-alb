variable "kops_cluster_name" {
  type        = "string"
  description = "Kubernetes cluster name"
}

variable "kops_ig_nodes_names" {
  type        = "list"
  description = "List of name of instance-group nodes managed by kops"
  default     = ["nodes"]
}

variable "kubernetes_ingress_domain" {
  type        = "string"
  description = "Domain name for the external/internal ALB"
}

variable "kubernetes_ingress_port" {
  type        = "string"
  description = "Node port of the ingress controller"
  default     = 30080
}

variable "alb_external_allow_ip" {
  type        = "list"
  description = "List of IP addresses to allow to the external ALB"

  default = [
    "0.0.0.0/0", # all
  ]
}

variable "alb_internal_enabled" {
  type        = "string"
  description = "Enable the internal ALB (needed if the external ALB is not public)"
  default     = false
}

locals {
  # Hash of kops_cluster_name and kubernetes_ingress_domain
  cluster_name_hash = "${substr(sha256("${var.kops_cluster_name}/${var.kubernetes_ingress_domain}"), 0, 16)}"
}
