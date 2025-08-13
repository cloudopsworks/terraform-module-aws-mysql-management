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
        try(var.databases[user.db_ref].create_owner, false) ? mysql_user.owner[user.db_ref].name :
        var.databases[user.db_ref].owner
      ) : user.database_owner
    }
  }
}

resource "mysql_grant" "user_all_db" {
  for_each = {
    for key, user in var.users : key => user if try(user.grant, "") == "owner"
  }
  database = try(each.value.db_ref, "") != "" ? mysql_database.this[each.value.db_ref].name : each.value.database_name
  role     = mysql_user.user[each.key].name
  privileges = [
    "ALL PRIVILEGES"
  ]
}
