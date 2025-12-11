##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

data "aws_db_instance" "db" {
  count                  = try(var.rds.enabled, false) && !try(var.rds.cluster, false) ? 1 : 0
  db_instance_identifier = nonsensitive(try(var.rds.name, local.from_secret["dbInstanceIdentifier"]))
}

data "aws_rds_cluster" "db" {
  count              = try(var.rds.enabled, false) && try(var.rds.cluster, false) ? 1 : 0
  cluster_identifier = nonsensitive(try(var.rds.name, local.from_secret["dbClusterIdentifier"]))
}

data "aws_db_instance" "hoop_db_server" {
  count                  = local.hoop_connect && !try(var.hoop.cluster, false) ? 1 : 0
  db_instance_identifier = var.hoop.server_name
}

data "aws_rds_cluster" "hoop_db_server" {
  count              = local.hoop_connect && try(var.hoop.cluster, false) ? 1 : 0
  cluster_identifier = var.hoop.server_name
}

data "aws_secretsmanager_secret" "db_password" {
  count = try(var.rds.enabled, false) || try(var.rds.from_secret, false) ? 1 : 0
  name  = var.rds.secret_name
}

data "aws_secretsmanager_secret_version" "db_password" {
  count     = try(var.rds.enabled, false) || try(var.rds.from_secret, false) ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.db_password[0].id
}
