##
# (c) 2021-2026
#     Cloud Ops Works LLC - https://cloudops.works/
#     Find us on:
#       GitHub: https://github.com/cloudopsworks
#       WebSite: https://cloudops.works
#     Distributed Under Apache v2.0 License
#

# Retain these declarations permanently. They preserve all for_each instances
# because the destination resources use the same keys as the former resources.
moved {
  from = mysql_database.this
  to   = module.db.mysql_database.this
}

moved {
  from = mysql_user.owner
  to   = module.db.mysql_user.owner
}

moved {
  from = mysql_user.user
  to   = module.db.mysql_user.user
}

# Import blocks must remain in this root module. Their destinations follow the
# moved resources so existing and newly imported configurations share addresses.
import {
  for_each = {
    for key, db in var.databases : key => db if try(db.create, true) && try(db.import, false)
  }
  to = module.db.mysql_database.this[each.key]
  id = each.value.name
}

import {
  for_each = {
    for key, db in var.databases : key => db if try(db.import, false) && try(db.create_owner, false)
  }
  to = module.db.mysql_user.owner[each.key]
  id = local.owner_list[each.key]
}

import {
  for_each = {
    for key, user in var.users : key => user if try(user.import, false)
  }
  to = module.db.mysql_user.user[each.key]
  id = each.value.name
}
