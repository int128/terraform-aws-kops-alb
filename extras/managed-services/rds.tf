resource "aws_db_subnet_group" "allow_from_k8s_nodes" {
  name       = "allow-from-nodes.${var.kubernetes_cluster_name}"
  subnet_ids = ["${data.aws_subnet_ids.kops_subnets.ids}"]
  tags       = "${map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "owned")}"
}

resource "aws_db_instance" "rds_for_k8s_nodes" {
  # Network
  availability_zone      = "${data.aws_availability_zones.available.names[0]}"
  vpc_security_group_ids = ["${aws_security_group.allow_from_k8s_nodes.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.rds_for_k8s_nodes.name}"
  publicly_accessible    = false

  # Spec
  identifier              = "kubernetes"
  instance_class          = "db.t2.micro"
  engine                  = "postgresql"
  engine_version          = "9.6"
  allocated_storage       = 20
  storage_type            = "gp2"
  username                = "${var.database_admin_username}"
  password                = "${var.database_admin_password}"
  parameter_group_name    = "default.postgres9.6"
  skip_final_snapshot     = true
  backup_retention_period = 7
  tags                    = "${map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "owned")}"

  lifecycle {
    ignore_changes = [
      "password",
      "allocated_storage",
    ]
  }
}
