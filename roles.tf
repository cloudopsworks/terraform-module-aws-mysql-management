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
  role       = mysql_role.role[each.key].name
  database   = try(each.value.database, "*")
  privileges = try(each.value.grant, ["ALL PRIVILEGES"])
}
