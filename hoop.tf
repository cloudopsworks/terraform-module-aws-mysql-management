##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  hoop_enabled       = try(var.hoop.enabled, false) && strcontains(local.psql.engine, "mysql")
  hoop_secret_prefix = try(var.hoop.community, true) ? "_aws" : "_envs/aws"
  hoop_secret_sep    = try(var.hoop.community, true) ? ":" : "#"
}

output "hoop_connections" {
  value = local.hoop_enabled ? merge(
    {
      for key, db in var.databases :
      "${local.psql.server_name}-${local.normalized_owner_list[key]}" => {
        name           = "${local.psql.server_name}-${local.normalized_owner_list[key]}"
        agent_id       = var.hoop.agent_id
        type           = "database"
        subtype        = "mysql"
        tags           = try(var.hoop.tags, {})
        access_control = toset(try(var.hoop.access_control, []))
        access_modes   = { connect = "enabled", exec = "enabled", runbooks = "enabled", schema = "enabled" }
        import         = try(var.hoop.import, false)
        secrets = {
          "envvar:HOST" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.owner[key].name}${local.hoop_secret_sep}host"
          "envvar:PORT" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.owner[key].name}${local.hoop_secret_sep}port"
          "envvar:USER" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.owner[key].name}${local.hoop_secret_sep}username"
          "envvar:PASS" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.owner[key].name}${local.hoop_secret_sep}password"
          "envvar:DB"   = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.owner[key].name}${local.hoop_secret_sep}dbname"
        }
      }
      if try(db.create_owner, false)
    },
    {
      for key, role_user in var.users :
      "${local.psql.server_name}-${try(role_user.db_ref, "") != "" ? (try(var.databases[role_user.db_ref].create, true) ? mysql_database.this[role_user.db_ref].name : var.databases[role_user.db_ref].name) : role_user.database_name}-${role_user.name}" => {
        name     = "${local.psql.server_name}-${try(role_user.db_ref, "") != "" ? (try(var.databases[role_user.db_ref].create, true) ? mysql_database.this[role_user.db_ref].name : var.databases[role_user.db_ref].name) : role_user.database_name}-${role_user.name}"
        agent_id = var.hoop.agent_id
        type     = "database"
        subtype  = "mysql"
        tags     = try(var.hoop.tags, {})
        access_control = setunion(
          toset(try(var.hoop.access_control, [])),
          toset(try(role_user.hoop.access_control, []))
        )
        access_modes = { connect = "enabled", exec = "enabled", runbooks = "enabled", schema = "enabled" }
        import       = try(var.hoop.import, false)
        secrets = {
          "envvar:HOST" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.user[key].name}${local.hoop_secret_sep}host"
          "envvar:PORT" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.user[key].name}${local.hoop_secret_sep}port"
          "envvar:USER" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.user[key].name}${local.hoop_secret_sep}username"
          "envvar:PASS" = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.user[key].name}${local.hoop_secret_sep}password"
          "envvar:DB"   = "${local.hoop_secret_prefix}${local.hoop_secret_sep}${aws_secretsmanager_secret.user[key].name}${local.hoop_secret_sep}dbname"
        }
      }
    }
  ) : null
  precondition {
    condition     = !local.hoop_enabled || try(var.hoop.agent_id, "") != ""
    error_message = "hoop.agent_id must be set (as a Hoop agent UUID) when hoop.enabled is true."
  }
}
