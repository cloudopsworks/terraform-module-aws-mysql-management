##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  owner_list = {
    for key, db in var.databases : key => "${db.name}_ow" if try(db.create_owner, false)
  }
}

resource "time_rotating" "owner" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name == ""
  }
  rotation_days = var.password_rotation_period
}

resource "random_password" "owner" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name == ""
  }
  length           = 25
  special          = true
  override_special = "=_-+@~#"
  min_upper        = 2
  min_special      = 2
  min_numeric      = 2
  min_lower        = 2
  lifecycle {
    replace_triggered_by = [
      time_rotating.owner[each.key].rotation_rfc3339
    ]
  }
}

resource "random_password" "owner_initial" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false) && var.rotation_lambda_name != ""
  }
  length           = 25
  special          = true
  override_special = "=_-+~#"
  min_upper        = 2
  min_special      = 2
  min_numeric      = 2
  min_lower        = 2
}

resource "mysql_database" "this" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create, true)
  }
  name                  = each.value.name
  default_character_set = try(each.value.default_character_set, null)
  default_collation     = try(each.value.default_collation, null)
}

resource "mysql_user" "owner" {
  depends_on = [mysql_database.this]
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false)
  }
  user = local.owner_list[each.key]
  host = try(each.value.host, null)
  plaintext_password = var.rotation_lambda_name == "" ? random_password.owner[each.key].result : (
    try(length(data.aws_secretsmanager_secret_versions.owner_rotated[each.key].versions), 0) > 0 && !var.force_reset ?
    jsondecode(data.aws_secretsmanager_secret_version.owner_rotated[each.key].secret_string)["password"] :
    random_password.owner_initial[each.key].result
  )
  tls_option = try(each.value.tls_option, null)
}

resource "mysql_grant" "owner" {
  depends_on = [mysql_user.owner]
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false)
  }
  user     = mysql_user.owner[each.key].user
  host     = mysql_user.owner[each.key].host
  database = try(var.databases[each.key].create, true) == true ? mysql_database.this[each.key].name : var.databases[each.key].name
  privileges = [
    "ALL PRIVILEGES"
  ]
  grant = true
}