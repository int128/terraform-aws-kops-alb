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

# Elasticsearch for Kubernetes logs
resource "aws_elasticsearch_domain" "logs" {
  domain_name           = "logs-${local.kubernetes_cluster_name_hash}"
  elasticsearch_version = "6.2"

  cluster_config {
    instance_type          = "t2.small.elasticsearch"
    zone_awareness_enabled = false
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  vpc_options {
    subnet_ids         = ["${data.aws_subnet_ids.kops_subnets.ids[0]}"]
    security_group_ids = ["${aws_security_group.allow_from_k8s_nodes.id}"]
  }

  tags = "${merge(
    map("kubernetes.io/cluster/${var.kubernetes_cluster_name}", "owned"),
    map("Name", "logs.${var.kubernetes_cluster_name}")
  )}"
}

resource "aws_iam_service_linked_role" "es" {
  # https://github.com/terraform-providers/terraform-provider-aws/issues/5218
  aws_service_name = "es.amazonaws.com"
}

data "aws_iam_policy_document" "es_logs_access" {
  statement {
    actions = [
      "es:*",
    ]

    resources = [
      "${aws_elasticsearch_domain.logs.arn}",
      "${aws_elasticsearch_domain.logs.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_elasticsearch_domain_policy" "es_logs_access" {
  domain_name     = "${aws_elasticsearch_domain.logs.domain_name}"
  access_policies = "${data.aws_iam_policy_document.es_logs_access.json}"
}

output "es_logs_endpoint" {
  value = "${aws_elasticsearch_domain.logs.endpoint}"
}

# RDS
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
