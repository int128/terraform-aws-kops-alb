resource "aws_efs_file_system" "efs_provisioner" {
  tags = "${merge(
    map("kubernetes.io/cluster/${var.kops_cluster_name}", "owned"),
    map("Name", "efs.${var.kops_cluster_name}")
  )}"
}

resource "aws_efs_mount_target" "efs_provisioner" {
  count           = "${length(data.aws_subnet_ids.kops_subnets.ids)}"
  file_system_id  = "${aws_efs_file_system.efs_provisioner.id}"
  subnet_id       = "${data.aws_subnet_ids.kops_subnets.ids[count.index]}"
  security_groups = ["${aws_security_group.allow_from_k8s_nodes.id}"]
}
