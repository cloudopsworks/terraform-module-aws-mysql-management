##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  owner_name_list = {
    for key, db in var.databases : key => format("%s/%s/%s/%s/%s-rds-credentials",
      local.secret_store_path,
      local.psql.engine,
      local.psql.server_name,
      replace(db.name, "_", "-"),
      replace(local.owner_list[key], "_", "-")
    )
    if try(db.create_owner, false)
  }
}
# # Secrets saving
data "aws_lambda_function" "rotation_function" {
  count         = var.rotation_lambda_name != "" ? 1 : 0
  function_name = var.rotation_lambda_name
}

## DB OWNER
resource "aws_secretsmanager_secret" "owner" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false)
  }
  name        = local.owner_name_list[each.key]
  description = "RDS Owner credentials - ${local.owner_list[each.key]} - ${local.psql.engine} - ${local.psql.server_name} - ${try(var.databases[each.key].create, true) == true ? mysql_database.this[each.key].name : var.databases[each.key].name}"
  kms_key_id  = var.secrets_kms_key_id
  tags = merge(local.all_tags, {
    "rds-username"        = local.owner_list[each.key]
    "rds-datatabase-name" = try(var.databases[each.key].create, true) == true ? mysql_database.this[each.key].name : var.databases[each.key].name
    "rds-server-name"     = local.psql.server_name
  })
}

resource "aws_secretsmanager_secret_version" "owner" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name == ""
  }
  secret_id = aws_secretsmanager_secret.owner[each.key].id
  secret_string = jsonencode({
    username = local.owner_list[each.key]
    password = random_password.owner[each.key].result
    host = local.hoop_connect ? (
      try(var.hoop.cluster, false) ? data.aws_rds_cluster.hoop_db_server[0].endpoint :
      data.aws_db_instance.hoop_db_server[0].address
    ) : local.psql.host
    port = local.hoop_connect ? (
      try(var.hoop.cluster, false) ? data.aws_rds_cluster.hoop_db_server[0].port :
      data.aws_db_instance.hoop_db_server[0].port
    ) : local.psql.port
    dbname = try(var.databases[each.key].create, true) == true ? mysql_database.this[each.key].name : var.databases[each.key].name
    engine = local.psql.engine
  })
}

data "aws_secretsmanager_secrets" "owner" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name != ""
  }
  filter {
    name = "name"
    values = [
      local.owner_name_list[each.key]
    ]
  }
}

data "aws_secretsmanager_secret_versions" "owner_rotated" {
  for_each = {
  for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name != "" && length(try(data.aws_secretsmanager_secrets.owner[key].names, [])) > 0 }
  secret_id          = local.owner_name_list[each.key]
  include_deprecated = true
}

data "aws_secretsmanager_secret_version" "owner_rotated" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name != "" && length(try(data.aws_secretsmanager_secrets.owner[key].names, [])) > 0 && length(try(data.aws_secretsmanager_secret_versions.owner_rotated[key].versions, [])) > 0
  }
  secret_id = local.owner_name_list[each.key]
}


resource "aws_secretsmanager_secret_version" "owner_rotated" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name != ""
  }
  secret_id = aws_secretsmanager_secret.owner[each.key].id
  secret_string = jsonencode({
    username = local.owner_list[each.key]
    password = (
      try(length(data.aws_secretsmanager_secret_versions.owner_rotated[each.key].versions), 0) > 0 && !var.force_reset ?
      jsondecode(data.aws_secretsmanager_secret_version.owner_rotated[each.key].secret_string)["password"] :
      random_password.owner_initial[each.key].result
    )
    host = local.hoop_connect ? (
      try(var.hoop.cluster, false) ? data.aws_rds_cluster.hoop_db_server[0].endpoint :
      data.aws_db_instance.hoop_db_server[0].address
    ) : local.psql.host
    port = local.hoop_connect ? (
      try(var.hoop.cluster, false) ? data.aws_rds_cluster.hoop_db_server[0].port :
      data.aws_db_instance.hoop_db_server[0].port
    ) : local.psql.port
    dbname = try(var.databases[each.key].create, true) == true ? mysql_database.this[each.key].name : var.databases[each.key].name
    engine = local.psql.engine
  })
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

resource "aws_secretsmanager_secret_rotation" "owner" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name != ""
  }
  secret_id           = aws_secretsmanager_secret.owner[each.key].arn
  rotation_lambda_arn = data.aws_lambda_function.rotation_function[0].arn
  rotate_immediately  = var.rotate_immediately
  rotation_rules {
    automatically_after_days = var.password_rotation_period
    duration                 = var.rotation_duration
  }
  depends_on = [
    aws_secretsmanager_secret_version.owner_rotated
  ]
}