##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

module "hoop_owners" {
  for_each = {
    for key, db in var.databases : key => db
    if try(db.create_owner, false) && try(var.hoop.enabled, false) && try(var.hoop.agent_id, "") != ""
  }
  source   = "./hoop"
  name     = format("%s-%s-ow", local.psql.server_name, (try(var.databases[each.key].create, true) == true ? mysql_database.this[each.key].name : var.databases[each.key].name))
  type     = "database"
  subtype  = "mysql"
  agent_id = var.hoop.agent_id
  secrets = {
    "envvar:HOST" = "_aws:${aws_secretsmanager_secret.owner[each.key].name}:host"
    "envvar:PORT" = "_aws:${aws_secretsmanager_secret.owner[each.key].name}:port"
    "envvar:USER" = "_aws:${aws_secretsmanager_secret.owner[each.key].name}:username"
    "envvar:PASS" = "_aws:${aws_secretsmanager_secret.owner[each.key].name}:password"
    "envvar:DB"   = "_aws:${aws_secretsmanager_secret.owner[each.key].name}:dbname"
  }
  access_modes = {
    connect  = "enabled"
    exec     = "enabled"
    runbooks = "enabled"
    schema   = "enabled"
  }
  tags           = var.hoop.tags
  access_control = setunion(toset(try(var.hoop.access_control, [])), toset(try(each.value.hoop.access_control, [])))
}

module "hoop_users" {
  for_each = {
    for key, role_user in var.users : key => role_user
    if try(var.hoop.enabled, false) && try(var.hoop.agent_id, "") != ""
  }
  source = "./hoop"
  name = format("%s-%s-%s",
    local.psql.server_name,
    (try(each.value.db_ref, "") != "" ? (try(var.databases[each.value.db_ref].create, true) == true ? mysql_database.this[each.value.db_ref].name : var.databases[each.value.db_ref].name) : each.value.database_name),
  each.value.name)
  type     = "database"
  subtype  = "mysql"
  agent_id = var.hoop.agent_id
  secrets = {
    "envvar:HOST" = "_aws:${aws_secretsmanager_secret.user[each.key].name}:host"
    "envvar:PORT" = "_aws:${aws_secretsmanager_secret.user[each.key].name}:port"
    "envvar:USER" = "_aws:${aws_secretsmanager_secret.user[each.key].name}:username"
    "envvar:PASS" = "_aws:${aws_secretsmanager_secret.user[each.key].name}:password"
    "envvar:DB"   = "_aws:${aws_secretsmanager_secret.user[each.key].name}:dbname"
  }
  access_modes = {
    connect  = "enabled"
    exec     = "enabled"
    runbooks = "enabled"
    schema   = "enabled"
  }
  tags           = var.hoop.tags
  access_control = setunion(toset(try(var.hoop.access_control, [])), toset(try(each.value.hoop.access_control, [])))
}
