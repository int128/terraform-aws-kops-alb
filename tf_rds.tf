# Resources for managed services (e.g. RDS) accessed from Kubernetes nodes.

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

resource "aws_db_subnet_group" "rds_for_k8s_nodes" {
  name       = "rds-for-nodes.${var.kubernetes_cluster_name}"
  subnet_ids = ["${data.aws_subnet_ids.kops_subnets.ids}"]
  tags       = "${map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "owned")}"
}

resource "aws_db_instance" "rds_for_k8s_nodes" {
  # Disable by default (this is a just example)
  count = 0

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
