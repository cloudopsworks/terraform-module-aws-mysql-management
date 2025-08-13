##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "mysql_grant" "user_tab_def_priv" {
  for_each = {
    for key, user in var.users : key => user if try(user.grant, "") == "readwrite"
  }
  database = try(each.value.db_ref, "") != "" ? mysql_database.this[each.value.db_ref].name : each.value.database_name
  user     = mysql_user.user[each.key].name
  table    = "*"
  privileges = [
    "SELECT",
    "INSERT",
    "UPDATE",
    "DELETE",
    "EXECUTE",
  ]
  depends_on = [
    mysql_database.this,
  ]
}

# resource "postgresql_default_privileges" "user_seq_def_priv" {
#   for_each = {
#     for key, user in var.users : key => user if try(user.grant, "") == "readwrite"
#   }
#   database    = try(each.value.db_ref, "") != "" ? mysql_database.this[each.value.db_ref].name : each.value.database_name
#   role        = postgresql_role.user[each.key].name
#   owner       = local.admin_role[each.key].admin_role
#   object_type = "sequence"
#   schema      = try(each.value.schema, "public")
#   privileges = [
#     "SELECT",
#     "UPDATE",
#   ]
#   depends_on = [
#     mysql_database.this,
#     postgresql_schema.database_schema,
#   ]
# }
#
# resource "postgresql_grant" "user_seq_def_priv" {
#   for_each = {
#     for key, user in var.users : key => user if try(user.grant, "") == "readwrite"
#   }
#   database    = try(each.value.db_ref, "") != "" ? mysql_database.this[each.value.db_ref].name : each.value.database_name
#   role        = postgresql_role.user[each.key].name
#   object_type = "sequence"
#   schema      = try(each.value.schema, "public")
#   privileges = [
#     "SELECT",
#     "UPDATE",
#   ]
#   depends_on = [
#     mysql_database.this,
#     postgresql_schema.database_schema,
#   ]
# }
#
# resource "postgresql_default_privileges" "user_func_def_priv" {
#   for_each = {
#     for key, user in var.users : key => user if try(user.grant, "") == "readwrite"
#   }
#   database    = try(each.value.db_ref, "") != "" ? mysql_database.this[each.value.db_ref].name : each.value.database_name
#   role        = postgresql_role.user[each.key].name
#   owner       = local.admin_role[each.key].admin_role
#   object_type = "function"
#   schema      = try(each.value.schema, "public")
#   privileges = [
#     "EXECUTE",
#   ]
#   depends_on = [
#     mysql_database.this,
#     postgresql_schema.database_schema,
#   ]
# }
#
# resource "postgresql_grant" "user_func_def_priv" {
#   for_each = {
#     for key, user in var.users : key => user if try(user.grant, "") == "readwrite"
#   }
#   database    = try(each.value.db_ref, "") != "" ? mysql_database.this[each.value.db_ref].name : each.value.database_name
#   role        = postgresql_role.user[each.key].name
#   object_type = "function"
#   schema      = try(each.value.schema, "public")
#   privileges = [
#     "EXECUTE",
#   ]
#   depends_on = [
#     mysql_database.this,
#     postgresql_schema.database_schema,
#   ]
# }
#
# resource "postgresql_default_privileges" "user_types_def_priv" {
#   for_each = {
#     for key, user in var.users : key => user if try(user.grant, "") == "readwrite"
#   }
#   database    = try(each.value.db_ref, "") != "" ? mysql_database.this[each.value.db_ref].name : each.value.database_name
#   role        = postgresql_role.user[each.key].name
#   owner       = local.admin_role[each.key].admin_role
#   object_type = "type"
#   schema      = try(each.value.schema, "public")
#   privileges = [
#     "USAGE",
#   ]
#   depends_on = [
#     mysql_database.this,
#     postgresql_schema.database_schema,
#   ]
# }
#
