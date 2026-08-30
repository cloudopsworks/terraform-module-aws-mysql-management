##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

locals {
  admin_role = {
    for key, user in var.users : key => {
      name = user.name
      admin_role = try(user.db_ref, "") != "" ? (
        try(var.databases[user.db_ref].create_owner, false) ? module.db.owner_usernames[user.db_ref] :
        var.databases[user.db_ref].owner
      ) : user.database_owner
    }
  }
}

resource "mysql_grant" "user_all_db" {
  for_each = {
    for key, user in var.users : key => user if try(user.grant, "") == "owner"
  }
  database = try(each.value.db_ref, "") != "" ? (
    try(var.databases[each.value.db_ref].create, true) == true ? local.database_names[each.value.db_ref] : var.databases[each.value.db_ref].name
  ) : each.value.database_name
  user = module.db.user_usernames[each.key]
  host = coalesce(try(each.value.host, null), "%")
  privileges = [
    "ALL PRIVILEGES"
  ]
}