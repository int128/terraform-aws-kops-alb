# An example with AWS Managed Services.

data "aws_availability_zones" "available" {}

resource "aws_db_instance" "rds_for_k8s_nodes" {
  # Disable by default
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
  username                = "kubernetes"
  password                = "kubernetes"
  parameter_group_name    = "default.postgres9.6"
  backup_retention_period = 7
}
