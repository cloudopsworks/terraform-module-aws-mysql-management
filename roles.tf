##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Roles have no passwords.
resource "mysql_role" "role" {
  for_each = var.roles
  name     = each.value.name
}

resource "mysql_grant" "role" {
  for_each = {
    for k, role in var.roles : k => role if try(role.grant, "") != ""
  }
  role = mysql_role.role[each.key].name
  database = try(each.value.db_ref, "") != "" ? (
    try(var.databases[each.value.db_ref].create, true) == true ? mysql_database.this[each.value.db_ref].name : var.databases[each.value.db_ref].name
  ) : try(each.value.database_name, "*")
  table      = try(each.value.table_name, "*")
  privileges = try(each.value.grants, ["ALL PRIVILEGES"])
  grant      = try(each.value.grant_option, null)
}
