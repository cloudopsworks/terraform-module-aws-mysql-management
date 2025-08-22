##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

#############
## ALL USERS
#############
locals {
  user_names_list = {
    for k, v in var.users : k => format("%s/%s/%s/%s/%s-rds-credentials",
      local.secret_store_path,
      local.psql.engine,
      local.psql.server_name,
      replace((try(v.db_ref, "") != "" ?
        var.databases[v.db_ref].name
        : v.database_name
      ), "_", "-"),
      replace(v.name, "_", "-")
    )
  }
  user_secrets_data = {
    for key, user in var.users : key => merge({
      username = user.name
      password = random_password.user[key].result
      host = local.hoop_connect ? (
        try(var.hoop.cluster, false) ? data.aws_rds_cluster.hoop_db_server[0].endpoint :
        data.aws_db_instance.hoop_db_server[0].address
      ) : local.psql.host
      port = local.hoop_connect ? (
        try(var.hoop.cluster, false) ? data.aws_rds_cluster.hoop_db_server[0].port :
        data.aws_db_instance.hoop_db_server[0].port
      ) : local.psql.port
      dbname = try(user.db_ref, "") != "" ? mysql_database.this[user.db_ref].name : user.database_name
      engine = local.psql.engine
      },
      length(data.aws_secretsmanager_secret.db_password) > 0 ? {
        masterarn = data.aws_secretsmanager_secret.db_password[0].arn
      } : {}
    ) if var.rotation_lambda_name == ""
  }
  user_secrets_data_merged = {
    for key, user_secret in local.user_secrets_data : key => merge(user_secret,
      try(var.users[key].connection_string_type, "") == "jdbc" ? {
        connection_string_type = var.users[key].connection_string_type
        connection_string = format("jdbc:mysql://%s:%s/%s?user=%s&password=%s&useSSL=true",
          user_secret.host, user_secret.port, user_secret.dbname,
          user_secret.username, urlencode(user_secret.password)
        )
      } : {},
      try(var.users[key].connection_string_type, "") == "dotnet" ? {
        connection_string_type = var.users[key].connection_string_type
        connection_string = format("Server=%s;Port=%s;Database=%s;Uid=%s;Pwd=%s;SslMode=Preferred",
          user_secret.host, user_secret.port,
          user_secret.dbname, user_secret.username, user_secret.password,
        )
      } : {},
      try(var.users[key].connection_string_type, "") == "odbc" ? {
        connection_string_type = var.users[key].connection_string_type
        connection_string = format("Driver={MySQL ODBC 5.2 UNICODE Driver};Server=%s;Port=%s;Database=%s;User=%s;Password=%s;Option=3;",
          user_secret.host, user_secret.port, user_secret.dbname,
          user_secret.username, user_secret.password
        )
      } : {},
      try(var.users[key].connection_string_type, "") == "gomysql" ? {
        connection_string_type = var.users[key].connection_string_type
        connection_string = format("%s:%s@tcp(%s):%s/%s?ssl=Preferred",
          user_secret.username, urlencode(user_secret.password), user_secret.host,
          user_secret.port, user_secret.dbname
        )
      } : {},
      # length(regexall("node|python", try(var.users[key].connection_string_type, ""))) > 0 ? {
      #   connection_string_type = var.users[key].connection_string_type
      #   connection_string = format("postgresql://%s:%s@tcp(%s:%s)/%s?ssl=Preferred",
      #     user_secret.username, urlencode(user_secret.password), user_secret.host,
      #     user_secret.port, user_secret.dbname
      #   )
      # } : {}
    )
  }
  user_rotated_secrets_data = {
    for key, user in var.users : key => merge({
      username = user.name
      password = (
        try(length(data.aws_secretsmanager_secret_versions.user_rotated[key].versions), 0) > 0 && !var.force_reset ?
        jsondecode(data.aws_secretsmanager_secret_version.user_rotated[key].secret_string)["password"] :
        random_password.user_initial[key].result
      )
      host = local.hoop_connect ? (
        try(var.hoop.cluster, false) ? data.aws_rds_cluster.hoop_db_server[0].endpoint :
        data.aws_db_instance.hoop_db_server[0].address
      ) : local.psql.host
      port = local.hoop_connect ? (
        try(var.hoop.cluster, false) ? data.aws_rds_cluster.hoop_db_server[0].port :
        data.aws_db_instance.hoop_db_server[0].port
      ) : local.psql.port
      dbname = try(user.db_ref, "") != "" ? mysql_database.this[user.db_ref].name : user.database_name
      engine = local.psql.engine
      },
      length(data.aws_secretsmanager_secret.db_password) > 0 ? {
        masterarn = data.aws_secretsmanager_secret.db_password[0].arn
      } : {}
    ) if var.rotation_lambda_name != ""
  }
  user_rotated_secrets_data_merged = {
    for key, user_secret in local.user_rotated_secrets_data : key => merge(user_secret,
      try(var.users[key].connection_string_type, "") == "jdbc" ? {
        connection_string_type = var.users[key].connection_string_type
        connection_string = format("jdbc:mysql://%s:%s/%s?user=%s&password=%s&useSSL=true",
          user_secret.host, user_secret.port, user_secret.dbname,
          user_secret.username, user_secret.password
        )
      } : {},
      try(var.users[key].connection_string_type, "") == "dotnet" ? {
        connection_string_type = var.users[key].connection_string_type
        connection_string = format("Server=%s;Port=%s;Database=%s;Uid=%s;Pwd=%s;SslMode=Preferred",
          user_secret.host, user_secret.port,
          user_secret.dbname, user_secret.username, user_secret.password
        )
      } : {},
      try(var.users[key].connection_string_type, "") == "odbc" ? {
        connection_string_type = var.users[key].connection_string_type
        connection_string = format("Driver={MySQL ODBC 5.2 UNICODE Driver};Server=%s;Port=%s;Database=%s;User=%s;Password=%s;Option=3;",
          user_secret.host, user_secret.port, user_secret.dbname,
          user_secret.username, user_secret.password
        )
      } : {},
      try(var.users[key].connection_string_type, "") == "gomysql" ? {
        connection_string_type = var.users[key].connection_string_type
        connection_string = format("%s:%s@tcp(%s):%s/%s?ssl=Preferred",
          user_secret.username, urlencode(user_secret.password), user_secret.host,
          user_secret.port, user_secret.dbname
        )
      } : {},
      # length(regexall("node-pg|psycopg|rustpg", try(var.users[key].connection_string_type, ""))) > 0 ? {
      #   connection_string_type = var.users[key].connection_string_type
      #   connection_string = format("postgresql://%s:%s@%s:%s/%s?sslmode=%s&schema=%s",
      #     user_secret.username, urlencode(user_secret.password), user_secret.host,
      #     user_secret.port, user_secret.dbname, user_secret.sslmode,
      #   try(var.users[key].schema, "public"))
      # } : {}
    )
  }
}

resource "aws_secretsmanager_secret" "user" {
  for_each    = var.users
  name        = local.user_names_list[each.key]
  description = "RDS User Credentials - ${each.value.name} - Grants: ${each.value.grant} - ${local.psql.engine} - ${local.psql.server_name}"
  kms_key_id  = var.secrets_kms_key_id
  tags = merge(local.all_tags, {
    "rds-username" = each.value.name
    "rds-datatabase-name" = (try(each.value.db_ref, "") != "" ?
      mysql_database.this[each.value.db_ref].name
      : each.value.database_name
    )
    "rds-server-name" = local.psql.server_name
  })
}

resource "aws_secretsmanager_secret_version" "user" {
  for_each      = local.user_secrets_data_merged
  secret_id     = aws_secretsmanager_secret.user[each.key].id
  secret_string = jsonencode(each.value)
}

data "aws_secretsmanager_secrets" "user" {
  for_each = {
    for k, v in var.users : k => v if var.rotation_lambda_name != ""
  }
  filter {
    name = "name"
    values = [
      local.user_names_list[each.key]
    ]
  }
}

data "aws_secretsmanager_secret_versions" "user_rotated" {
  for_each = {
    for k, v in var.users : k => v if var.rotation_lambda_name != "" && length(data.aws_secretsmanager_secrets.user[k].names) > 0
  }
  secret_id          = local.user_names_list[each.key]
  include_deprecated = true
}

data "aws_secretsmanager_secret_version" "user_rotated" {
  for_each = {
    for k, v in var.users : k => v if var.rotation_lambda_name != "" && length(data.aws_secretsmanager_secrets.user[k].names) > 0 && try(length(data.aws_secretsmanager_secret_versions.user_rotated[k].versions), 0) > 0
  }
  secret_id = local.user_names_list[each.key]
}

resource "aws_secretsmanager_secret_version" "user_rotated" {
  for_each      = local.user_rotated_secrets_data_merged
  secret_id     = aws_secretsmanager_secret.user[each.key].id
  secret_string = jsonencode(each.value)
  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
}

resource "aws_secretsmanager_secret_rotation" "user" {
  for_each = {
    for k, v in var.users : k => v if var.rotation_lambda_name != ""
  }
  secret_id           = aws_secretsmanager_secret.user[each.key].arn
  rotation_lambda_arn = data.aws_lambda_function.rotation_function[0].arn
  rotate_immediately  = var.rotate_immediately
  rotation_rules {
    automatically_after_days = var.password_rotation_period
    duration                 = var.rotation_duration
  }
  depends_on = [
    aws_secretsmanager_secret_version.user_rotated
  ]
}
