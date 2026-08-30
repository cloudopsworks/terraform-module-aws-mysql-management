##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

resource "mysql_grant" "user_ro_tab_def_priv" {
  for_each = {
    for key, user in var.users : key => user if try(user.grant, "") == "readonly"
  }
  database = try(each.value.db_ref, "") != "" ? (
    try(var.databases[each.value.db_ref].create, true) == true ? local.database_names[each.value.db_ref] : var.databases[each.value.db_ref].name
  ) : each.value.database_name
  user  = module.db.user_usernames[each.key]
  host  = coalesce(try(each.value.host, null), "%")
  table = "*"
  privileges = [
    "SELECT",
  ]
  depends_on = [
    module.db,
  ]
}
