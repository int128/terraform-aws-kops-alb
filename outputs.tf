output "kops_cluster_name" {
  description = "Kubernetes cluster name"
  value       = "${var.kops_cluster_name}"
}

output "sgid_allow_from_nodes" {
  description = "ID of security group which is allowed from Kubernetes nodes"
  value       = "${aws_security_group.allow_from_k8s_nodes.id}"
}

output "kops_vpc_id" {
  description = "ID of VPC managed by kops"
  value       = "${data.aws_vpc.kops_vpc.id}"
}

output "kops_subnet_ids" {
  description = "IDs of subnets managed by kops"
  value       = "${data.aws_subnet_ids.kops_subnets.ids}"
}
