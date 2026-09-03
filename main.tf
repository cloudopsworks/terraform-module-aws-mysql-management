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

  # The same password gate module.db applies, evaluated here against this module's own
  # configuration. `module.db.owner_password_managed` / `user_password_managed` report the
  # identical decision, but they are derived from the maps this module feeds into module.db,
  # which under a rotation lambda carry `random_password.*_initial` — so gating those
  # resources on them would close a dependency cycle. `passwordless_auth_plugins` is a static
  # list with no such dependency, which is why the gate is re-evaluated from it here rather
  # than the plugin names being copied into this module.
  owner_password_suppressed = {
    for key, db in var.databases : key => (
      contains(module.db.passwordless_auth_plugins, try(lower(db.auth_plugin), ""))
      || try(db.auth_string, db.auth_string_hashed, null) != null
    ) if try(db.create_owner, false)
  }
  user_password_suppressed = {
    for key, user in var.users : key => (
      contains(module.db.passwordless_auth_plugins, try(lower(user.auth_plugin), ""))
      || try(user.auth_string, user.auth_string_hashed, null) != null
    )
  }

  # Accounts whose password this module has to carry through the rotation-lambda path. A
  # suppressed account is excluded: it authenticates without a stored password, so even the
  # very first seed would be unusable. Rotated and suppressed accounts can therefore be mixed
  # freely in the same `databases` / `users` map.
  owner_rotation_managed = {
    for key, db in var.databases : key => db
    if try(db.create_owner, false) && var.rotation_lambda_name != "" && !local.owner_password_suppressed[key]
  }
  user_rotation_managed = {
    for key, user in var.users : key => user
    if var.rotation_lambda_name != "" && !local.user_password_suppressed[key]
  }

  # Passwords under a rotation lambda: the value of record is whatever Secrets Manager
  # currently holds, and `random_password.owner_initial` only seeds the very first version.
  owner_rotated_passwords = {
    for key, db in local.owner_rotation_managed : key => (
      try(length(data.aws_secretsmanager_secret_versions.owner_rotated[key].versions), 0) > 0 && !var.force_reset ?
      jsondecode(data.aws_secretsmanager_secret_version.owner_rotated[key].secret_string)["password"] :
      random_password.owner_initial[key].result
    )
  }
  user_rotated_passwords = {
    for key, user in local.user_rotation_managed : key => (
      try(length(data.aws_secretsmanager_secret_versions.user_rotated[key].versions), 0) > 0 && !var.force_reset ?
      jsondecode(data.aws_secretsmanager_secret_version.user_rotated[key].secret_string)["password"] :
      random_password.user_initial[key].result
    )
  }

  # What module.db is told about each account's password, in a single uniform shape.
  #
  # The shape has to be uniform across every key: under a rotation lambda `password` is an
  # apply-time value, and if some entries carried the attribute while others omitted it,
  # module.db's `local.owner_users` / `local.users` would resolve to an unknown map and its
  # `time_rotating` for_each would fail to plan. Every entry therefore declares both
  # attributes, with `password = null` wherever there is nothing to hand over.
  #
  #   suppressed        → module.db generates nothing and stores nothing; the account
  #                       authenticates without a password.
  #   rotation lambda   → Secrets Manager holds the value of record; hand it over.
  #   otherwise         → module.db owns generation, rotation and force_reset.
  owner_password_inputs = {
    for key, db in var.databases : key => (
      local.owner_password_suppressed[key] ? { generate_password = false, password = null } :
      var.rotation_lambda_name != "" ? { generate_password = false, password = local.owner_rotated_passwords[key] } :
      { generate_password = true, password = null }
    ) if try(db.create_owner, false)
  }
  user_password_inputs = {
    for key, user in var.users : key => (
      local.user_password_suppressed[key] ? { generate_password = false, password = null } :
      var.rotation_lambda_name != "" ? { generate_password = false, password = local.user_rotated_passwords[key] } :
      { generate_password = true, password = null }
    )
  }

  owner_users = {
    for key, db in var.databases : key => merge(
      local.owner_account_settings[key],
      local.owner_password_inputs[key],
      {
        name = local.owner_list[key]
        # Grants stay at their existing addresses in this module (owner-grants.tf and the
        # per-privilege grant files), so module.db must not manage them.
        manage_grants = false
      },
    ) if try(db.create_owner, false)
  }

  mysql_users = {
    for key, user in var.users : key => merge(
      user,
      local.user_password_inputs[key],
      {
        resource_group = "user"
        manage_grants  = false
      },
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
      local.owner_password_suppressed[key] ? {} : { password = module.db.owner_passwords[key] }
    ) if try(db.create_owner, false)
  }
  user_stored_passwords = {
    for key, user in var.users : key => (
      local.user_password_suppressed[key] ? {} : { password = module.db.user_passwords[key] }
    )
  }
}

# Seeds the first Secrets Manager version under a rotation lambda. Not created for accounts
# whose auth_plugin authenticates without a stored password — the seed would be as unusable
# as any other password for them.
resource "random_password" "owner_initial" {
  for_each         = local.owner_rotation_managed
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
