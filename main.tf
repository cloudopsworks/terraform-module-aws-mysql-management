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

  # Account settings mapped straight through to `mysql_user` by module.db. Owner accounts
  # take theirs from the `databases` entry that declares them; regular users from their own
  # `users` entry. All are null when unset, which module.db turns into a server default.
  owner_account_settings = {
    for key, db in var.databases : key => {
      host                 = try(db.host, null)
      tls_option           = try(db.tls_option, null)
      auth_plugin          = try(db.auth_plugin, null)
      auth_string          = try(db.auth_string, db.auth_string_hashed, null)
      max_user_connections = try(db.max_user_connections, null)
      max_statement_time   = try(db.max_statement_time, null)
    } if try(db.create_owner, false)
  }

  # Passwords under a rotation lambda: the value of record is whatever Secrets Manager
  # currently holds, and `random_password.owner_initial` only seeds the very first version.
  # Handed to module.db with `generate_password = false` so it adopts the value instead of
  # generating one. Without a lambda this map is empty and module.db owns generation.
  owner_rotated_passwords = {
    for key, db in var.databases : key => {
      generate_password = false
      password = (
        try(length(data.aws_secretsmanager_secret_versions.owner_rotated[key].versions), 0) > 0 && !var.force_reset ?
        jsondecode(data.aws_secretsmanager_secret_version.owner_rotated[key].secret_string)["password"] :
        random_password.owner_initial[key].result
      )
    } if try(db.create_owner, false) && var.rotation_lambda_name != ""
  }
  user_rotated_passwords = {
    for key, user in var.users : key => {
      generate_password = false
      password = (
        try(length(data.aws_secretsmanager_secret_versions.user_rotated[key].versions), 0) > 0 && !var.force_reset ?
        jsondecode(data.aws_secretsmanager_secret_version.user_rotated[key].secret_string)["password"] :
        random_password.user_initial[key].result
      )
    } if var.rotation_lambda_name != ""
  }

  owner_users = {
    for key, db in var.databases : key => merge(
      local.owner_account_settings[key],
      {
        name = local.owner_list[key]
        # Grants stay at their existing addresses in this module (owner-grants.tf and the
        # per-privilege grant files), so module.db must not manage them.
        manage_grants = false
      },
      try(local.owner_rotated_passwords[key], {}),
    ) if try(db.create_owner, false)
  }

  mysql_users = {
    for key, user in var.users : key => merge(
      user,
      {
        resource_group = "user"
        manage_grants  = false
      },
      try(local.user_rotated_passwords[key], {}),
    )
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

  # Owner passwords this module has to store, resolved to a single map regardless of which
  # side generated them. Empty for accounts whose `auth_plugin` authenticates without a
  # password (RDS IAM auth, for example) — module.db withholds those and the secret carries
  # connection metadata only.
  owner_stored_passwords = {
    for key, db in var.databases : key => (
      module.db.owner_password_managed[key] ? { password = module.db.owner_passwords[key] } : {}
    ) if try(db.create_owner, false)
  }
  user_stored_passwords = {
    for key, user in var.users : key => (
      module.db.user_password_managed[key] ? { password = module.db.user_passwords[key] } : {}
    )
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
