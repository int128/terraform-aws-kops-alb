# Resources for managed services (e.g. EFS, RDS) accessed from Kubernetes nodes.

resource "aws_security_group" "allow_from_k8s_nodes" {
  name        = "allow-from-nodes.${var.kubernetes_cluster_name}"
  description = "Security group for managed services accessed from k8s nodes"
  vpc_id      = "${data.aws_vpc.kops_vpc.id}"
  tags        = "${map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "owned")}"

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

# EFS for Persistent Volumes
resource "aws_efs_file_system" "efs_provisioner" {
  tags = "${merge(
    map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "owned"),
    map("Name", "efs.${var.kubernetes_cluster_name}")
  )}"
}

resource "aws_efs_mount_target" "efs_provisioner" {
  count           = "${length(data.aws_subnet_ids.kops_subnets.ids)}"
  file_system_id  = "${aws_efs_file_system.efs_provisioner.id}"
  subnet_id       = "${data.aws_subnet_ids.kops_subnets.ids[count.index]}"
  security_groups = ["${aws_security_group.allow_from_k8s_nodes.id}"]
}

output "efs_provisoner_file_system_id" {
  value = "${aws_efs_file_system.efs_provisioner.id}"
}

# RDS
resource "aws_db_subnet_group" "rds_for_k8s_nodes" {
  name       = "rds-for-nodes.${var.kubernetes_cluster_name}"
  subnet_ids = ["${data.aws_subnet_ids.kops_subnets.ids}"]
  tags       = "${map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "owned")}"
}
