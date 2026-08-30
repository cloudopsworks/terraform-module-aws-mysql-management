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
  owner_users = {
    for key, db in var.databases : key => {
      name              = local.owner_list[key]
      host              = try(db.host, null)
      tls_option        = try(db.tls_option, null)
      import            = try(db.import, false)
      manage_grants     = false
      generate_password = false
      password = var.rotation_lambda_name == "" ? random_password.owner[key].result : (
        try(length(data.aws_secretsmanager_secret_versions.owner_rotated[key].versions), 0) > 0 && !var.force_reset ?
        jsondecode(data.aws_secretsmanager_secret_version.owner_rotated[key].secret_string)["password"] :
        random_password.owner_initial[key].result
      )
    } if try(db.create_owner, false)
  }
  mysql_users = {
    for key, user in var.users : key => merge(user, {
      resource_group    = "user"
      manage_grants     = false
      generate_password = false
      password = var.rotation_lambda_name == "" ? random_password.user[key].result : (
        try(length(data.aws_secretsmanager_secret_versions.user_rotated[key].versions), 0) > 0 && !var.force_reset ?
        jsondecode(data.aws_secretsmanager_secret_version.user_rotated[key].secret_string)["password"] :
        random_password.user_initial[key].result
      )
    })
  }
  mysql_databases = {
    for key, db in var.databases : key => merge(db, {
      default_character_set = try(db.default_character_set, null)
      default_collation     = try(db.default_collation, null)
    })
  }
  database_names = {
    for key, db in var.databases : key => (
      try(db.create, true) ? module.db.databases[key].name : db.name
    )
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
  special          = var.specials_in_password
  override_special = "=_-+@~#"
  min_upper        = 2
  min_special      = var.specials_in_password ? 2 : 0
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
  special          = var.specials_in_password
  override_special = "=_-+~#"
  min_upper        = 2
  min_special      = var.specials_in_password ? 2 : 0
  min_numeric      = 2
  min_lower        = 2
}

resource "mysql_grant" "owner" {
  for_each = {
    for key, db in var.databases : key => db if try(db.create_owner, false)
  }
  user     = module.db.owner_usernames[each.key]
  host     = coalesce(try(each.value.host, null), "%")
  database = local.database_names[each.key]
  privileges = [
    "ALL PRIVILEGES"
  ]
  grant = true
}
