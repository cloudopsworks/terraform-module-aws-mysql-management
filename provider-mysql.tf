##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  hoop_connect = try(var.hoop.enabled, false) && try(var.hoop.connection_name, "") != ""
  from_secret  = try(var.rds.enabled, false) || try(var.rds.from_secret, false) ? jsondecode(data.aws_secretsmanager_secret_version.db_password[0].secret_string) : {}
  rds_secret_psql = try(var.rds.from_secret, false) ? {
    server_name = nonsensitive(try(var.rds.server_name, "") != "" ? var.rds.server_name : try(local.from_secret["dbInstanceIdentifier"], local.from_secret["dbClusterIdentifier"]))
    host        = nonsensitive(local.from_secret["host"])
    port        = nonsensitive(local.from_secret["port"])
    username    = nonsensitive(local.from_secret["username"])
    password    = local.from_secret["password"]
    engine      = nonsensitive(local.from_secret["engine"])
    db_name     = nonsensitive(local.from_secret["dbname"])
  } : {}
  rds_psql = try(var.rds.enabled, false) && !try(var.rds.cluster, false) ? {
    server_name = data.aws_db_instance.db[0].id
    host        = data.aws_db_instance.db[0].address
    port        = data.aws_db_instance.db[0].port
    username    = data.aws_db_instance.db[0].master_username
    engine      = data.aws_db_instance.db[0].engine
    password    = local.from_secret["password"]
    db_name     = data.aws_db_instance.db[0].db_name
  } : {}
  rds_psql_c = try(var.rds.enabled, false) && try(var.rds.cluster, false) ? {
    server_name = data.aws_rds_cluster.db[0].cluster_identifier
    host        = data.aws_rds_cluster.db[0].endpoint
    port        = data.aws_rds_cluster.db[0].port
    username    = data.aws_rds_cluster.db[0].master_username
    engine      = data.aws_rds_cluster.db[0].engine
    password    = local.from_secret["password"]
    db_name     = data.aws_rds_cluster.db[0].database_name
  } : {}
  hoop_psql = local.hoop_connect ? {
    server_name = var.hoop.server_name
    host        = "localhost"
    port        = try(var.hoop.port, 3306)
    username    = try(var.hoop.username, "noop")
    password    = try(var.hoop.password, "noop")
    engine      = try(var.hoop.engine, "mysql")
    db_name     = var.hoop.db_name
  } : {}
  direct_psql = !try(var.rds.enabled, false) && !local.hoop_connect ? {
    server_name = var.direct.server_name
    host        = var.direct.host
    port        = var.direct.port
    jump_host   = try(var.direct.jump_host, "")
    jump_port   = try(var.direct.jump_port, "")
    username    = var.direct.username
    password    = var.direct.password
    engine      = try(var.direct.engine, "mysql")
    db_name     = var.direct.db_name
  } : null
  psql = merge(
    local.direct_psql,
    local.hoop_psql,
    local.rds_secret_psql,
    local.rds_psql,
    local.rds_psql_c,
  )
}

provider "mysql" {
  endpoint = format("%s:%s",
    try(local.psql.jump_host, "") != "" ? local.psql.jump_host : local.psql.host,
    try(local.psql.jump_port, "") != "" ? local.psql.jump_port : local.psql.port
  )
  username = local.psql.username
  password = local.psql.password
  tls      = "skip-verify"
}