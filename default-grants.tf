##
# (c) 2021-2025
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# resource "mysql_grant" "user_connect" {
#   for_each = {
#     for key, user in var.users : key => user if try(user.grant, "") != "owner"
#   }
#   depends_on = [mysql_database.this]
#   database   = try(each.value.db_ref, "") != "" ? (try(var.databases[each.value.db_ref].create, true) == true ? mysql_database.this[each.value.db_ref].name : var.databases[each.value.db_ref].name) : each.value.database_name
#   user       = mysql_user.user[each.key].name
#   privileges = ["CONNECT"]
# }
